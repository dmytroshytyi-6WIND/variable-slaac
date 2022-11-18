# variable SLAAC v2.X.X implementation in linux kernel 

[![Build Status](https://app.travis-ci.com/dmytroshytyi/variable-slaac.svg?branch=master&status=passed)](https://app.travis-ci.com/github/dmytroshytyi/variable-slaac)
[![Gitter](https://badges.gitter.im/dmytroshytyi/variable-slaac-linux-implementation.svg)](https://gitter.im/dmytroshytyi/variable-slaac-linux-implementation?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fdmytroshytyi%2Fvariable-slaac&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

## Release v2.X.X vs v1.X

Releases v1.X are relying on int128 variables.

Releases v2.X.X rewritten and are not relying on int128 variables.

## IETF documents: 

draft-mishra-6man-variable-slaac-01

draft-mishra-6man-variable-slaac-00


draft-mishra-v6ops-variable-slaac-problem-stmt-01

draft-mishra-v6ops-variable-slaac-problem-stmt-00

## Short description on the web site:

https://dmytro.shytyi.net/variable-slaac-ipv6-slaac-with-prefixes-of-arbitrary-length-in-pio/

## Linux kernel development branches

slaac_var_plen_net_next.patch - should be applied to "net-next" branch.


slaac_var_plen_net.patch - should be applied to "net" branch.


## Compatible linux kernels with patches in this repo:

### net-next branch

Linux ferby 5.10.0-rc2-00757-g8be33ecfc1ff-dirty #2 SMP PREEMPT Tue Nov 10 12:33:35 CET 2020 x86_64 GNU/Linux

### net branch

Linux kernel: Linux ferby 5.10.0-rc1-00133-gfffffda4fefb #1 SMP PREEMPT Mon Nov 2 21:42:42 CET 2020 x86_64 GNU/Linux

Linux kernel: Linux ferby 5.9.0-rc3-00357-gcc8e58f8325c-dirty #1 SMP PREEMPT Thu Sep 10 10:50:34 CEST 2020 x86_64 GNU/Linux

Please check tags/releases.


## Demo

### Default behaviour /bin/bash ip a sh

```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff
  inet6 2001:fa9e:c193:ae49:6285:be18:21c3:b437/16 scope global dynamic mngtmpaddr 
       valid_lft 86200sec preferred_lft 14200sec
    inet6 2000:2f97:42e2:109a:b8db:4c95:e081:4b/12 scope global dynamic mngtmpaddr 
       valid_lft 86114sec preferred_lft 14114sec
    inet6 2001:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128 scope global dynamic mngtmpaddr 
       valid_lft 86081sec preferred_lft 14081sec
    inet6 2001:ffff:ffff:ffff:ffff:ffff:ffff:fffe/127 scope global dynamic mngtmpaddr 
       valid_lft 86045sec preferred_lft 14045sec
    inet6 2001:ffff:ffff:ffc8:c7f6:3531:38dc:7304/57 scope global dynamic mngtmpaddr 
       valid_lft 86008sec preferred_lft 14008sec
    inet6 2001:ffff:ffff:ffff:ffff:ffff:fffe:3bbe/111 scope global dynamic mngtmpaddr 
       valid_lft 85957sec preferred_lft 13957sec
    inet6 2001:ffff:ffff:ffff:ffff:ffff:ffff:e2be/112 scope global dynamic mngtmpaddr 
       valid_lft 85930sec preferred_lft 13930sec
```




### Stable privacy + privacy extensions

#### Config

```
[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.use_tempaddr=2

[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.addr_gen_mode=3

[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.addr_gen_mode=2
```

#### /bin/bash ip a sh

```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff
    inet6 2001:ffff:fffe:8d2c:df24:d0db:f0ec:3f28/47 scope global temporary dynamic 
       valid_lft 85677sec preferred_lft 13677sec
    inet6 2001:ffff:fffe:a23:889d:d522:fad9:5e5/47 scope global dynamic mngtmpaddr stable-privacy 
       valid_lft 85677sec preferred_lft 13677sec
    inet6 fe80::4428:b0ca:1844:6247/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000

```
    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff
    inet6 2001:ffff:ffff:ffff:fff2:cf59:8f4c:9ac1/72 scope global temporary dynamic 
       valid_lft 86381sec preferred_lft 14381sec
    inet6 2001:ffff:ffff:ffff:ffbc:601b:dba0:12f1/72 scope global dynamic mngtmpaddr stable-privacy 
       valid_lft 86381sec preferred_lft 14381sec
    inet6 fe80::2b2b:e2ce:d353:2d38/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

## TESTING: compilation process did not throw errors during net/ipv6/addrconf.c processing:

### with script downloaded from this link

wget https://raw.githubusercontent.com/intel/lkp-tests/master/sbin/make.cross -O ~/bin/make.cross 

### with the next command execution 

make -j8 for x86_64

COMPILER_INSTALL_PATH=~/0day COMPILER=gcc-10.2.0 ../../bin/make.cross  ARCH=sh  2>&1 | tee build.log

COMPILER_INSTALL_PATH=~/0day COMPILER=gcc-10.2.0 ../../bin/make.cross  ARCH=arm  2>&1 | tee build.log


### with these architectures

#### x86_64

[awesome@ferby net-next-patch-v2-5.10.0-rc2]$ make -j16

	
#### SuperH

```
[awesome@ferby net-next-patch-v2-5.10.0-rc2]$ compiler_install_path=~/0day compiler=gcc-10.2.0 ../../bin/make.cross  arch=sh  2>&1 | tee build.log
Compiler will be installed in /home/awesome/0day
make W=1 CONFIG_OF_ALL_DTBS=y CONFIG_DTC=y CROSS_COMPILE=/home/awesome/0day/gcc-10.2.0-nolibc/sh4-linux/bin/sh4-linux- --jobs=16 ARCH=sh
make[1]: 'include/generated/machtypes.h' is up to date.
  CALL    scripts/atomic/check-atomics.sh
  CALL    scripts/checksyscalls.sh
...
  CHK     kernel/kheaders_data.tar.xz
  CC [M]  net/ipv6/addrconf.o
  LD [M]  net/ipv6/ipv6.o
...
```

#### ARM

```
[awesome@ferby net-next-patch-v2-5.10.0-rc2]$ compiler_install_path=~/0day compiler=gcc-10.2.0 ../../bin/make.cross  arch=arm  2>&1 | tee build.log
Compiler will be installed in /home/awesome/0day 
make W=1 CONFIG_OF_ALL_DTBS=y CONFIG_DTC=y CROSS_COMPILE=/home/awesome/0day/gcc-10.2.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi- --jobs=16 ARCH=arm 
...
  CC [M]  sound/soc/qcom/qdsp6/q6dsp-common.o
  LD [M]  sound/soc/pxa/snd-soc-pxa2xx.o
  CC [M]  sound/soc/qcom/lpass-cpu.o
  CC [M]  net/netfilter/nft_nat.o
  CC [M]  net/ipv6/addrconf.o
  CC [M]  drivers/regulator/wm831x-dcdc.o
  CC [M]  sound/soc/qcom/qdsp6/q6core.o
...
```
