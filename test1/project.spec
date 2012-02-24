define PUBLISH .publish

# vim:set syntax=tcl:

Load settings.conf

define? AUTOREMAKE [file-src configure] --conf=[file-src auto.def]

# Arrange to re-run configure if auto.def changes
Depends settings.conf auto.def -do {
	note "Configure"
	run [set AUTOREMAKE] >config.out
}
Clean config.out config.log
DistClean settings.conf
