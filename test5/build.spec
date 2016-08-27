ifconfig CONFIGURED

SharedLib --install=/lib --version=1.0.0 mdns mDNSCore/DNSCommon.c mDNSCore/DNSDigest.c mDNSCore/mDNS.c mDNSCore/uDNS.c \
		mDNSPosix/mDNSPosix.c mDNSPosix/mDNSUNP.c mDNSShared/GenLinkedList.c \
		mDNSShared/PlatformCommon.c mDNSShared/dnssd_ipc.c mDNSShared/mDNSDebug.c

Executable --install=/bin mdnsd mDNSPosix/PosixDaemon.c mDNSShared/uds_daemon.c

#
# Client library only.
#
SharedLib --install=/lib dns_sd mDNSShared/dnssd_clientlib.c mDNSShared/dnssd_clientstub.c

Executable --install=/bin mDNSClientPosix mDNSPosix/ExampleClientApp.c mDNSPosix/Client.c
Executable --install=/bin mDNSResponderPosix  mDNSPosix/Responder.c
