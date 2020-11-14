#!/usr/bin/env bash

set -eu

setup_variables() {
    while [[ ${#} -ge 1 ]]; do
        case ${1} in
            "AR="* | "ARCH="* | "CC="* | "LD="* | "LLVM="* | "LLVM_IAS="* | "NM"=* | "OBJCOPY"=* | "OBJDUMP"=* | "OBJSIZE"=* | "REPO="* | "STRIP"=*) export "${1?}" ;;
            "-c" | "--clean") cleanup=true ;;
            "-j" | "--jobs")
                shift
                jobs=$1
                ;;
            "-j"*) jobs=${1/-j/} ;;
            "--lto") disable_lto=false ;;
            "-h" | "--help")
                cat usage.txt
                exit 0
                ;;
        esac

        shift
    done

    if [ "${ARCH:-0}" -eq "0" ]; then
        cat usage.txt
        exit 1
    fi

    # Turn on debug mode after parameters in case -h was specified
    set -x

    # torvalds/linux is the default repo if nothing is specified
    case ${REPO:=net-next} in
        "android"*)
            tree=common
            branch=${REPO}
            url=https://android.googlesource.com/kernel/${tree}
            ;;
        "linux")
            owner=torvalds
            tree=linux
            ;;
        "linux-next")
            owner=next
            tree=linux-next
            ;;
	"net-next")
	    owner=next
	    tree=net-next
	    ;;
        "4.4" | "4.9" | "4.14" | "4.19" | "5.4")
            owner=stable
            branch=linux-${REPO}.y
            tree=linux
            ;;
    esac
    [[ -z "${url:-}" ]] && url=git://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git

    SUBARCH=${ARCH}
    case ${SUBARCH} in
        "arm32_v5")
            config=multi_v5_defconfig
            make_target=zImage
            export ARCH=arm
            export CROSS_COMPILE=arm-linux-gnueabi-
            ;;

        "arm32_v6")
            config=aspeed_g5_defconfig
            make_target=zImage
            timeout=4 # This architecture needs a bit of a longer timeout due to some flakiness on Travis
            export ARCH=arm
            export CROSS_COMPILE=arm-linux-gnueabi-
            ;;

        "arm32_v7")
            config=multi_v7_defconfig
            make_target=zImage
            export ARCH=arm
            export CROSS_COMPILE=arm-linux-gnueabi-
            ;;

        "arm64")
            case ${REPO} in
                android-*)
                    case ${branch} in
                        *4.9-q | *4.14-stable) config=cuttlefish_defconfig ;;
                        *) config=gki_defconfig ;;
                    esac
                    ;;
                *) config=defconfig ;;
            esac
            make_target=Image.gz
            timeout=8 # '-cpu max' with QEMU takes longer to boot, increase timeout to 8m for Travis
            export CROSS_COMPILE=aarch64-linux-gnu-
            ;;

        "mips")
            config=malta_kvm_guest_defconfig
            make_target=vmlinux
            export ARCH=mips
            export CROSS_COMPILE=mips-linux-gnu-
            ;;

        "mipsel")
            config=malta_kvm_guest_defconfig
            make_target=vmlinux
            export ARCH=mips
            export CROSS_COMPILE=mipsel-linux-gnu-
            ;;

        "ppc32")
            config=ppc44x_defconfig
            make_target=uImage
            export ARCH=powerpc
            export CROSS_COMPILE=powerpc-linux-gnu-
            ;;

        "ppc64")
            config=pseries_defconfig
            make_target=vmlinux
            export ARCH=powerpc
            export CROSS_COMPILE=powerpc64-linux-gnu-
            ;;

        "ppc64le")
            config=powernv_defconfig
            make_target=zImage.epapr
            export ARCH=powerpc
            export CROSS_COMPILE=powerpc64le-linux-gnu-
            ;;

        "riscv")
            config=defconfig
            make_target=Image
            export CROSS_COMPILE=riscv64-linux-gnu-
            ;;

        "s390")
            BOOT=false
            config=defconfig
            make_target=bzImage
            export CROSS_COMPILE=s390x-linux-gnu-

            # llvm-objcopy: error: invalid output format: 'elf64-s390'
            # https://github.com/llvm/llvm-project/blob/llvmorg-11-init/llvm/tools/llvm-objcopy/CopyConfig.cpp#L242-L275
            OBJCOPY=${CROSS_COMPILE}objcopy
            OBJDUMP=${CROSS_COMPILE}objdump
            ;;

        "x86")
            config=i386_defconfig
            make_target=bzImage
            export ARCH=i386
            ;;

        "x86_64")
            case ${REPO} in
                android-*)
                    case ${branch} in
                        *4.9-q | *4.14-stable) config=x86_64_cuttlefish_defconfig ;;
                        *) config=gki_defconfig ;;
                    esac
                    ;;
                *)
                    config=defconfig
                    ;;
            esac
            make_target=bzImage
            ;;

        # Unknown arch, error out
        *)
            echo "Unknown ARCH specified!"
            exit 1
            ;;
    esac
    export ARCH=${ARCH}
}

# Clone/update the boot-utils
# It would be nice to use submodules for this but those don't always play well with Travis
# https://github.com/ClangBuiltLinux/continuous-integration/commit/e9054499bb1cb1a51cd1cdc73dc3c1dfa45b4199
function update_boot_utils() {
    images_url=https://github.com/ClangBuiltLinux/boot-utils
    if [[ -d boot-utils ]]; then
        cd boot-utils
        git fetch --depth=1 ${images_url} master
        git reset --hard FETCH_HEAD
        cd ..
    else
        git clone --depth=1 ${images_url}
    fi
}

check_dependencies() {
    # Check for existence of needed binaries
    command -v nproc
    command -v timeout
    command -v unbuffer
    command -v zstd

    update_boot_utils

    oldest_llvm_version=7
    latest_llvm_version=$(curl -LSs https://raw.githubusercontent.com/llvm/llvm-project/master/llvm/CMakeLists.txt | grep -s -F "set(LLVM_VERSION_MAJOR" | cut -d ' ' -f 4 | sed 's/)//')

    for llvm_version in $(seq "${latest_llvm_version}" -1 "${oldest_llvm_version}"); do
        debian_llvm_bin=/usr/lib/llvm-${llvm_version}/bin
        if [[ -d ${debian_llvm_bin} ]]; then
            export PATH=${debian_llvm_bin}:${PATH}
            break
        fi
    done

    READELF=llvm-readelf
    command -v "${READELF}"

    # Check for LD, CC, and AR environmental variables
    # and print the version string of each. If CC and AR
    # don't exist, try to find them.
    # clang's integrated assembler and lld aren't ready for all architectures so
    # it's just simpler to fall back to GNU as/ld when AS/LD isn't specified to
    # avoid architecture specific selection logic.

    "${LD:="${CROSS_COMPILE:-}"ld}" --version
    if [[ -z "${LLVM_IAS:-}" ]]; then
        LLVM_IAS=0
        command -v "${CROSS_COMPILE:-}"as
    fi

    if [[ -z "${CC:-}" ]]; then
        CC=clang
        command -v "${CC}"
    fi
    ${CC} --version 2>/dev/null || {
        set +x
        echo
        echo "Looks like ${CC} could not be found in PATH!"
        echo
        echo "Please install as recent a version of clang as you can from your distro or"
        echo "properly specify the CC variable to point to the correct clang binary."
        echo
        echo "If you don't want to install clang, you can either download AOSP's prebuilt"
        echo "clang [1] or build it from source [2] then add the bin folder to your PATH."
        echo
        echo "[1]: https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/"
        echo "[2]: https://github.com/ClangBuiltLinux/linux/wiki/Building-Clang-from-source"
        echo
        exit
    }

    if [[ -z "${AR:-}" ]]; then
        for AR in llvm-ar "${CROSS_COMPILE:-}"ar; do
            command -v "${AR}" 2>/dev/null && break
        done
    fi
    check_ar_version
    "${AR}" --version

    if [[ -z "${NM:-}" ]]; then
        for NM in llvm-nm "${CROSS_COMPILE:-}"nm; do
            command -v "${NM}" 2>/dev/null && break
        done
    fi

    if [[ -z "${OBJCOPY:-}" ]]; then
        for OBJCOPY in llvm-objcopy "${CROSS_COMPILE:-}"objcopy; do
            command -v "${OBJCOPY}" 2>/dev/null && break
        done
    fi

    if [[ -z "${OBJDUMP:-}" ]]; then
        for OBJDUMP in llvm-objdump "${CROSS_COMPILE:-}"objdump; do
            command -v "${OBJDUMP}" 2>/dev/null && break
        done
    fi

    if [[ -z "${OBJSIZE:-}" ]]; then
        for OBJSIZE in llvm-size "${CROSS_COMPILE:-}"size; do
            command -v "${OBJSIZE}" 2>/dev/null && break
        done
    fi

    if [[ -z "${STRIP:-}" ]]; then
        for STRIP in llvm-strip "${CROSS_COMPILE:-}"strip; do
            command -v "${STRIP}" 2>/dev/null && break
        done
    fi

    check_objcopy_strip_version
    "${OBJCOPY}" --version
    "${STRIP}" --version
}

# Optimistically check to see that the user has a llvm-ar
# with https://reviews.llvm.org/rL354044. If they don't,
# fall back to GNU ar and let them know.
check_ar_version() {
    if ${AR} --version | grep -q "LLVM" &&
        [[ $(${AR} --version | grep version | sed -e 's/.*LLVM version //g' -e 's/[[:blank:]]*$//' -e 's/\.//g' -e 's/svn//' -e 's/git//') -lt 900 ]]; then
        set +x
        echo
        echo "${AR} found but appears to be too old to build the kernel (needs to be at least 9.0.0)."
        echo
        echo "Please either update llvm-ar from your distro or build it from source!"
        echo
        echo "See https://github.com/ClangBuiltLinux/linux/issues/33 for more info."
        echo
        echo "Falling back to GNU ar..."
        echo
        AR=${CROSS_COMPILE:-}ar
        set -x
    fi
}

# Optimistically check to see that the user has an llvm-{objcopy,strip}
# with https://reviews.llvm.org/rGedeebad7715774b8481103733dc5d52dac43bdf3.
# If they don't, fall back to GNU objcopy and let them know.
check_objcopy_strip_version() {
    for TOOL in ${OBJCOPY} ${STRIP}; do
        if ${TOOL} --version | grep -q "LLVM" &&
            [[ $(${TOOL} --version | grep version | sed -e 's/.*LLVM version //g' -e 's/[[:blank:]]*$//' -e 's/\.//g' -e 's/svn//' -e 's/git//') -lt 1000 ]]; then
            set +x
            echo
            echo "${TOOL} found but appears to be too old to build the kernel (needs to be at least 10.0.0)."
            echo
            echo "Please either update ${TOOL} from your distro or build it from source!"
            echo
            echo "See https://github.com/ClangBuiltLinux/linux/issues/478 for more info."
            echo
            echo "Falling back to GNU ${TOOL//llvm-/}..."
            echo
            case ${TOOL} in
                *objcopy*) OBJCOPY=${CROSS_COMPILE:-}objcopy ;;
                *strip*) STRIP=${CROSS_COMPILE:-}strip ;;
            esac
            set -x
        fi
    done
}
mako_reactor() {
    if [[ ${LLVM:-0} -eq "1" ]]; then
        time \
            KBUILD_BUILD_TIMESTAMP="Thu Jan  1 00:00:00 UTC 1970" \
            KBUILD_BUILD_USER=driver \
            KBUILD_BUILD_HOST=clangbuiltlinux \
            make -j"${jobs:-$(nproc)}" \
            LLVM=1 \
            LLVM_IAS="${LLVM_IAS}" \
            "${@}"
    else
        # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/kbuild/kbuild.txt
        time \
            KBUILD_BUILD_TIMESTAMP="Thu Jan  1 00:00:00 UTC 1970" \
            KBUILD_BUILD_USER=driver \
            KBUILD_BUILD_HOST=clangbuiltlinux \
            make -j"${jobs:-$(nproc)}" \
            AR="${AR}" \
            CC="${CC}" \
            HOSTCC="${CC}" \
            HOSTLD="${HOSTLD:-ld}" \
            KCFLAGS="-Wno-implicit-fallthrough" \
            LD="${LD}" \
            LLVM_IAS="${LLVM_IAS}" \
            NM="${NM}" \
            OBJCOPY="${OBJCOPY}" \
            OBJDUMP="${OBJDUMP}" \
            OBJSIZE="${OBJSIZE}" \
            READELF="${READELF}" \
            STRIP="${STRIP}" \
            "${@}"
    fi
}

apply_patches() {
    patches_folder=$1
    if [[ -d ${patches_folder} ]]; then
        git apply -v -3 "${patches_folder}"/*.patch
    else
        return 0
    fi
}

build_linux() {
    # Wrap CC in ccache if it is available (it's not strictly required)
    CC="$(command -v ccache) ${CC}"
    [[ ${LD} =~ lld ]] && HOSTLD=${LD}

    if [[ -d ${tree} ]]; then
        cd ${tree}
        git fetch --depth=1 ${url} ${branch:=master}
        git reset --hard FETCH_HEAD
    else
        git clone --depth=1 -b ${branch:=master} --single-branch ${url}
        cd ${tree}
    fi

    git show -s | cat

    llvm_all_folder="../patches/llvm-all"
    apply_patches "${llvm_all_folder}/kernel-all"
    apply_patches "${llvm_all_folder}/${REPO}/arch-all"
    apply_patches "${llvm_all_folder}/${REPO}/${SUBARCH}"
    llvm_version_folder="../patches/llvm-$(echo __clang_major__ | ${CC} -E -x c - | tail -n 1)"
    apply_patches "${llvm_version_folder}/kernel-all"
    apply_patches "${llvm_version_folder}/${REPO}/arch-all"
    apply_patches "${llvm_version_folder}/${REPO}/${SUBARCH}"

    # Only clean up old artifacts if requested, the Linux build system
    # is good about figuring out what needs to be rebuilt
    [[ -n "${cleanup:-}" ]] && mako_reactor mrproper
    mako_reactor ${config}
    # If we're using a defconfig, enable some more common config options
    # like debugging, selftests, and common drivers
    if [[ ${config} =~ defconfig ]]; then
        cat ../configs/common.config >>.config
        # Some torture test configs cause issues on PowerPC and x86_64
        [[ $ARCH != "x86_64" && $ARCH != "powerpc" ]] && cat ../configs/tt.config >>.config
        # For RISC-V, disable a couple of configs:
        # * CONFIG_EFI: https://github.com/ClangBuiltLinux/linux/issues/1143
        # * CONFIG_KALLSYMS_ALL: https://github.com/ClangBuiltLinux/linux/issues/1144
        # Every other configuration option disabled is to get rid of CONFIG_KALLSYMS_ALL.
        if [[ $ARCH = "riscv" ]]; then
            ./scripts/config \
                -d DEBUG_LOCK_ALLOC \
                -d DEBUG_WW_MUTEX_SLOWPATH \
                -d EFI \
                -d KALLSYMS_ALL \
                -d LOCK_STAT \
                -d PROVE_LOCKING
        fi
        # Disable LTO and CFI unless explicitly requested
        ${disable_lto:=true} && ./scripts/config -d CONFIG_LTO -d CONFIG_LTO_CLANG
    fi
    [[ $SUBARCH == "mips" ]] && ./scripts/config -e CPU_BIG_ENDIAN -d CPU_LITTLE_ENDIAN
    # Make sure we build with CONFIG_DEBUG_SECTION_MISMATCH so that the
    # full warning gets printed and we can file and fix it properly.
    ./scripts/config -e DEBUG_SECTION_MISMATCH
    mako_reactor olddefconfig &>/dev/null
    mako_reactor ${make_target}
    [[ $ARCH =~ arm ]] && mako_reactor dtbs
    "${READELF}" --string-dump=.comment vmlinux

    cd "${OLDPWD}"
}

boot_qemu() {
    ${BOOT:=true} || return 0
    ./boot-utils/boot-qemu.sh -a "${SUBARCH}" -k "${tree}" -t "${timeout:-2}"m
}

setup_variables "${@}"
check_dependencies
build_linux
boot_qemu
