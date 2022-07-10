# vim:set syntax=tcl:
define? DESTDIR _install

define? AUTOREMAKE ./configure --host=arm-linux-gnueabi TOPBUILDDIR=$TOPBUILDDIR --conf=auto.def

Autosetup include/autoconf.h

ifconfig CONFIGURED

IncludePaths mDNSCore mDNSShared

CFlags -DMDNS_UDS_SERVERPATH=\"/var/run/mdnsd\" \
    -DPID_FILE=\"/var/run/mdnsd.pid\" \
    -DNOT_HAVE_SA_LEN \
    -DMDNS_DEBUGMSGS=0 \
    -DOPENSSL_NO_ASM

CFlags -Wno-deprecated-declarations


if {[string match *-linux* [get-define host]]} {
        CFlags -DUSES_NETLINK -DHAVE_LINUX
}
