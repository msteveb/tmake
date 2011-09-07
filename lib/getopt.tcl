# Copyright (c) 2006 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Simple getopt module

# optdef looks something like:
# --test --install: dest source args
#
# Sets variables in the caller's scope with the names given in optdef, except
# any remaining args are left in the original argv
#
# If --test is set, then test=1, otherwise test=0
# If --install is specified, $install is set, otherwise it left unset

proc getopt {optdef argvname} {
	upvar $argvname argv
	set nargv {}

	# Parse the options
	set haveargs 0
	set named {}
	foreach i $optdef {
		if {[regexp {^--([^:]*)(:)?$} $i -> name colon]} {
			if {$colon eq ":"} {
				set valopts($name) 1
				#uplevel 1 unset -nocomplain $name
			} else {
				set boolopts($name) 0
			}
			continue
		}
		if {$i eq "args"} {
			incr haveargs
		} else {
			lappend named $i
		}
	}
	#parray valopts
	#parray boolopts
	#puts named=$named
	#puts haveargs=$haveargs
	#puts args=$argv

	for {set i 0} {$i < [llength $argv]} {incr i} {
		set arg [lindex $argv $i]

		#dputs arg=$arg

		if {$arg eq "--"} {
			# End of options
			incr i
			break
		}

		if {[regexp {^--([^=]+)=(.*)} $arg -> name value]} {
			# --abc=def
			if {![info exists valopts($name)]} {
				if {[info exists boolopts($name)]} {
					dev-error "Option --$name does not accept a parameter"
				}
				dev-error "Unknown option: --$name"
			}
			uplevel 1 set $name $value
		} elseif {[regexp {^--(.*)} $arg -> name]} {
			# --abc
			if {![info exists boolopts($name)]} {
				if {[info exists valopts($name)} {
					dev-error "Option --$name requires a parameter"
				}
				dev-error "Unknown option: --$name"
			}
			set boolopts($name) 1
		} else {
			lappend nargv $arg
		}
	}
	foreach i [array names boolopts] {
		uplevel 1 set $i $boolopts($i)
	}
	if {!$haveargs && [llength $nargv] > [llength $named]} {
		dev-error "Too many parameters"
	}
	if {[llength $named]} {
		set argv [uplevel 1 [list lassign $nargv {*}$named]]
	} else {
		set argv $nargv
	}
}
