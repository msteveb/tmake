# Initial project.spec created by 'autosetup --init=tmake'

# vim:set syntax=tcl:
define PUBLISH .publish
define? DESTDIR _install

# XXX If configure creates additional/different files than include/autoconf.h
#     that should be reflected here

# We use [set AUTOREMAKE] here to avoid rebuilding settings.conf
# if the AUTOREMAKE command changes
Depends {settings.conf include/autoconf.h} auto.def -msg {note Configuring...} -do {
	run [set AUTOREMAKE] >$build/config.out
} -onerror {puts [readfile $build/config.out]} -fatal
Clean config.out
DistClean --src config.log
DistClean settings.conf include/autoconf.h

# If not configured, configure with default options
# Note that it is expected that configure will normally be run 
# separately. This is just a convenience for a host build
define? AUTOREMAKE configure TOPBUILDDIR=$TOPBUILDDIR --conf=auto.def

Load settings.conf

# e.g. for up autoconf.h
IncludePaths include

ifconfig CONFIGURED

use util
Phony showvars -do {
	dump-vars
}

CFlags -Werror
