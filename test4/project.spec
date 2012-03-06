# load autosetup settings
define? AUTOREMAKE configure

# Arrange to re-run configure if auto.def changes
Depends {settings.conf autoconfig.h} auto.def -do {
	note "Configure..."
	run [set AUTOREMAKE] >$build/config.out
} -onerror {puts [readfile $build/config.out]}
Clean config.out config.log
DistClean settings.conf autoconfig.h

Load settings.conf
