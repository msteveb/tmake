# vim:set syntax=tcl:

# ----- standard autosetup prolog ------
# If auto.def creates other files they should be added here
Depends {settings.conf} auto.def -do {
	note "Configure..."
	run [set AUTOREMAKE] >config.out
}
Clean config.out config.log
DistClean settings.conf

Load settings.conf
define? AUTOREMAKE configure
