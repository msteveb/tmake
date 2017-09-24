# vim:set syntax=tcl:

use pkg-config

Autosetup {jimautoconf.h jim-config.h}

DefaultOptions Executable --strip=none --install=/tmp
DefaultOptions SharedLib --strip
DefaultOptions SharedObject --strip
