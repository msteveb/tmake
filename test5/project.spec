Load settings.conf

Depends settings.conf -do {
	user-error "Run ./configure first"
}

IncludePaths mDNSCore mDNSShared

CFlags -DMDNS_UDS_SERVERPATH=\"/var/run/mdnsd\" \
    -DPID_FILE=\"/var/run/mdnsd.pid\" \
    -DNOT_HAVE_SA_LEN \
    -DMDNS_DEBUGMSGS=0
	
CFlags -Wno-deprecated-declarations

if {[string match  *-linux* $host]} {
	CFlags -DUSES_NETLINK -DHAVE_LINUX
}

