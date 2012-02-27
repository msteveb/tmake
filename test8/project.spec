# Minimal autosetup
Load settings.conf

define? AUTOREMAKE [file-src configure] --conf=[file-src auto.def]

Depends settings.conf auto.def -do {
	note "Configure"
	run [set AUTOREMAKE] >config.out
} -onerror {puts [readfile config.out]}
Clean config.out config.log
DistClean settings.conf
