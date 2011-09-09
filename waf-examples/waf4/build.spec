# vim:set syntax=tcl:

# ----- standard autosetup prolog ------
Load settings.conf
define? AUTOREMAKE configure

# If auto.def creates other files they should be added here
Depends {settings.conf} auto.def -do {
	note "Configure..."
	run [set AUTOREMAKE] >config.out
}
Clean config.out config.log
DistClean settings.conf

# The rest of the build description is only used if configured
ifconfig CONFIGURED
# ----- standard autosetup prolog ------

# ----- packacing - dist, distcheck ------
define PACKAGE_NAME waf4
define PACKAGE_VERSION 1.0
define PKGBASE $PACKAGE_NAME-$PACKAGE_VERSION
define PKGFILE $PKGBASE.tar.gz

Phony dist -msg {note Dist $PKGFILE} -do {
	file mkdir distbuilddir/$PKGBASE
	run git ls-files | cpio -pmud distbuilddir/$PKGFILE
	run tar -C distbuilddir -cf - $PKGBASE | gzip >$PKGFILE
	file delete -force distbuilddir
}

Phony distcheck distcheck.sh dist -msg {note DistCheck} -do {
	run sh distcheck.sh $PKGBASE
}
DistClean $PKGFILE
# ------------- packaging --------------

# Some real rules
Generate foo.txt {} {} {
	writefile $target "empty file!"
}

CopyFile bar.txt foo.txt

Depends all bar.txt
