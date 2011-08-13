# Copyright (c) 2006 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Simple getopt module

proc getopt {optdef argvname} {
	upvar $argvname argv

	# Parse everything out of the argv list which looks like an option
	# Knows about --enable-thing and --disable-thing as alternatives for --thing=0 or --thing=1
	# Everything which doesn't look like an option, or is after --, is left unchanged
	upvar $argvname argv
	set nargv {}

	# Initialise all boolean options to 0
	# String options are unset
	foreach i $optdef {
		if {![string match *: $i]} {
			set opts($i) 0
		}
	}

	for {set i 0} {$i < [llength $argv]} {incr i} {
		set arg [lindex $argv $i]

		#dputs arg=$arg

		if {$arg eq "--"} {
			# End of options
			incr i
			lappend nargv {*}[lrange $argv $i end]
			break
		}

		if {[regexp {^--([^=]+)=(.*)} $arg -> name value]} {
			# --abc=def
			if {"$name:" ni $optdef} {
				if {$name in $optdef} {
					error "getopt: Option --$name does not accept a parameter"
				}
				error "getopt: Unknown option: --$name"
			}
			set opts($name) $value
		} elseif {[regexp {^--(.*)} $arg -> name]} {
			# --abc
			if {$name ni $optdef} {
				if {"$name:" in $optdef} {
					error "getopt: Option --$name requires a parameter"
				}
				error "getopt: Unknown option: --$name"
			}
			set opts($name) 1
		} else {
			lappend nargv $arg
		}
	}

	#puts "getopt: argv=[join $argv] => [join $nargv]"
	#parray opts

	set argv $nargv

	return [array get opts]
}
