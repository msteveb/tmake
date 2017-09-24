# Initial project.spec created by 'autosetup --init=tmake'

# vim:set syntax=tcl:
define PUBLISH .publish
define? DESTDIR _install

Autosetup include/autoconf.h

# e.g. for up autoconf.h
IncludePaths include

ifconfig !CONFIGURED {
	# Not configured, so don't process subdirs
	AutoSubDirs off
	# And don't process this file any further
	ifconfig false
}

use util
Phony showvars -do {
	dump-vars
}

CFlags -Werror
