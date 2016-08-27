# vim:set syntax=tcl:
define? DESTDIR _install

Depends settings.conf auto.def -msg {note Configuring...} -do {
	run [set AUTOREMAKE] >$build/config.out
} -onerror {puts [readfile $build/config.out]} -fatal
Clean config.out
DistClean --source config.log
DistClean settings.conf

define? AUTOREMAKE configure --host=arm-linux TOPBUILDDIR=$TOPBUILDDIR --conf=auto.def

Load settings.conf

ifconfig CONFIGURED

IncludePaths mDNSCore mDNSShared

CFlags -DMDNS_UDS_SERVERPATH=\"/var/run/mdnsd\" \
    -DPID_FILE=\"/var/run/mdnsd.pid\" \
    -DNOT_HAVE_SA_LEN \
    -DMDNS_DEBUGMSGS=0

CFlags -Wno-deprecated-declarations


if {[string match *-linux* [get-define host]]} {
        CFlags -DUSES_NETLINK -DHAVE_LINUX
}
