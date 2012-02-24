# load autosetup settings
Load settings.conf
define? AUTOREMAKE [file-src configure] --conf=[file-src auto.def]

# Arrange to re-run configure if auto.def changes
Depends {settings.conf autoconfig.h} auto.def -do {
	note "Configure..."
	run [set AUTOREMAKE] >config.out
} -onerror {puts [readfile config.out]}
Clean config.out config.log
DistClean settings.conf autoconfig.h

