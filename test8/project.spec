# Minimal autosetup
define? AUTOREMAKE configure

Depends settings.conf auto.def -do {
	note "Configure"
	run [set AUTOREMAKE] >$build/config.out
} -onerror {puts [readfile $build/config.out]}
Clean config.out config.log
DistClean settings.conf

Load settings.conf
