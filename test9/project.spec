# load autosetup settings
define? AUTOREMAKE configure

# Arrange to re-run configure if auto.def changes
Depends {settings.conf config.h} auto.def -do {
	note "Configure..."
	run [set AUTOREMAKE] >$build/config.out
} -onerror {puts [readfile $build/config.out]}
Clean config.out
DistClean settings.conf config.h
Clean --src config.log

Load settings.conf
