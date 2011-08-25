# vim:set syntax=tcl:

Load --required settings.conf

# Arrange to re-run configure if auto.def changes
Depends settings.conf auto.def -do {
	note "Configure"
	run $AUTOREMAKE >config.out
}
