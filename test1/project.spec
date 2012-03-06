define PUBLISH .publish
define? DESTDIR _install

# vim:set syntax=tcl:

# Arrange to re-run configure if auto.def changes
Depends settings.conf auto.def configure -do {
	note "Configure"
	run [set AUTOREMAKE] >$TOPBUILDDIR/config.out
}
Clean config.out config.log
DistClean settings.conf tmake.opt

Load settings.conf

define? AUTOREMAKE configure TOPBUILDDIR=$TOPBUILDDIR --conf=auto.def

use util
Phony blah -do {
	dump-vars
}
