# Initial project.spec created by 'autosetup --init=tmake'

# vim:set syntax=tcl:
define PUBLISH .publish
define? DESTDIR _install

Autosetup include/autoconf.h

# e.g. for up autoconf.h
IncludePaths include

ifconfig CONFIGURED

use util
Phony showvars -do {
	dump-vars
}

CFlags -Werror
