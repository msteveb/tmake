
LocalMakefile GNUmakefile

#ifconfig USER_MDNSRESPONDER

IncludePath mdnsresponder/mDNSCore mdnsresponder/mDNSShared

CFlags -DMDNS_UDS_SERVERPATH=\"/var/run/mdnsd\" \
    -DPID_FILE=\"/var/run/mdnsd.pid\" \
    -DNOT_HAVE_SA_LEN \
    -DMDNS_DEBUGMSGS=0
	
#ifconfig USER_MDNSRESPONDER_IPV6 {
#	CFlags -DHAVE_IPV6=1
#}

CFlags -Wno-deprecated-declarations

#if {[string match  *-linux* [config TARGET_PLATFORM]]} {
#	CFlags -DUSES_NETLINK -DHAVE_LINUX
#}

Lib mdns mDNSCore/DNSCommon.c mDNSCore/DNSDigest.c mDNSCore/mDNS.c mDNSCore/uDNS.c \
		mDNSPosix/mDNSPosix.c mDNSPosix/mDNSUNP.c mDNSShared/GenLinkedList.c \
		mDNSShared/PlatformCommon.c mDNSShared/dnssd_ipc.c mDNSShared/mDNSDebug.c

Executable --install=/bin mdnsd mDNSPosix/PosixDaemon.c mDNSShared/uds_daemon.c

#
# Client library only.
#
Lib dns_sd mDNSShared/dnssd_clientlib.c mDNSShared/dnssd_clientstub.c

Executable --install=/bin mDNSClientPosix mDNSPosix/ExampleClientApp.c mDNSPosix/Client.c
Executable --install=/bin mDNSResponderPosix  mDNSPosix/Responder.c
