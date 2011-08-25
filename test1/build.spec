# vim:set syntax=tcl:

# Arrange to re-run configure if auto.def changes

Depends settings.conf auto.def -do {
	note "Configure"
	if {![info exists AUTOREMAKE]} {
		user-error "No settings.conf. Run ./configure"
	}
	run $AUTOREMAKE >config.out
}
