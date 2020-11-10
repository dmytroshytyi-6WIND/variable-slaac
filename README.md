# variable SLAAC 
## IETF documents: 

draft-mishra-6man-variable-slaac-01

draft-mishra-6man-variable-slaac-00


draft-mishra-v6ops-variable-slaac-problem-stmt-01

draft-mishra-v6ops-variable-slaac-problem-stmt-00

## Branches

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

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000

    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff

    inet6 2001:ffff:ffff:ff36:a542:5743:57f0:2919/56 scope global dynamic mngtmpaddr 

       valid_lft 86385sec preferred_lft 14385sec

    inet6 2001:ffff:ffff:ffff:ff5b:df35:35e1:f932/72 scope global dynamic mngtmpaddr 

       valid_lft 86357sec preferred_lft 14357sec

    inet6 2001:ffff:ffff:ffff:ffff:ffff:ffff:fed0/119 scope global dynamic mngtmpaddr 

       valid_lft 86320sec preferred_lft 14320sec

    inet6 2001:ffff:ffff:ffff:ffff:ffff:ffff:311f/111 scope global dynamic mngtmpaddr 

       valid_lft 86258sec preferred_lft 14258sec

    inet6 fe80::a00:27ff:fe59:e717/64 scope link 

       valid_lft forever preferred_lft forever


### Stable privacy + privacy extensions

#### Config

[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.use_tempaddr=2

[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.addr_gen_mode=3

[awesome@ferby ~]$ sudo sysctl net.ipv6.conf.enp0s3.addr_gen_mode=2

#### /bin/bash ip a sh

2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000

    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff

    inet6 2001:ffff:ffff:ffeb:6c11:2e0:37e1:3b45/56 scope global temporary dynamic 

       valid_lft 86395sec preferred_lft 14395sec

    inet6 2001:ffff:ffff:ff3a:c9bc:601b:dba0:12f1/56 scope global dynamic mngtmpaddr stable-privacy 

       valid_lft 86395sec preferred_lft 14395sec

    inet6 fe80::2b2b:e2ce:d353:2d38/64 scope link stable-privacy 

       valid_lft forever preferred_lft forever



2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000

    link/ether 08:00:27:59:e7:17 brd ff:ff:ff:ff:ff:ff

    inet6 2001:ffff:ffff:ffff:fff2:cf59:8f4c:9ac1/72 scope global temporary dynamic 

       valid_lft 86381sec preferred_lft 14381sec

    inet6 2001:ffff:ffff:ffff:ffbc:601b:dba0:12f1/72 scope global dynamic mngtmpaddr stable-privacy 

       valid_lft 86381sec preferred_lft 14381sec

    inet6 fe80::2b2b:e2ce:d353:2d38/64 scope link stable-privacy 

       valid_lft forever preferred_lft forever

