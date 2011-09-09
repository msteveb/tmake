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

Phony dist -do {
	run git ls-files
}
