# Copyright (c) 2006 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Simple getopt module

# Implements the core of getopt
# Returns a list of {vars newargv}
# Where $vars is a list of {name value ...} corresponding to the set options
# and $newargv contains any unused args (always {} unless 'args' is given)
#
proc getopt-core {optdef argv} {
	set nargv {}
	set boolopts {}
	set stropts {}

	set vars {}

	# Parse the option definition
	set haveargs 0
	set named {}
	foreach i $optdef {
		if {[regexp {^--([^:]*)(:*)$} $i -> name colon]} {
			#puts "$i -> $name, [string length $colon]"
			switch [string length $colon] {
				0 {
					if {[string match *|* $name]} {
						lassign [split $name |] prefix name
						set boolopts($prefix$name) [list $name 0]
					}
					# boolopts($name) stores a list of the actual option name and the
					# value to set
					set boolopts($name) [list $name 1]
					set vars($name) 0
				}
				1 {
					set stropts($name) 1
				}
				2 {
					set stropts($name) 2
					set vars($name) {}
				}
				default {
					parse-error "Bad getopt specification: $i"
				}
			}
			continue
		}
		if {$i eq "args"} {
			incr haveargs
		} else {
			lappend named $i
		}
	}
	#parray stropts
	#parray boolopts
	#parray vars
	#puts named=$named
	#puts haveargs=$haveargs
	#puts args=$argv

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
			if {![info exists stropts($name)]} {
				if {[info exists boolopts($name)]} {
					parse-error "Option --$name does not accept a parameter"
				}
				parse-error "Unknown option: --$name"
			}
			if {$stropts($name) == 1} {
				if {[info exists seen($name)]} {
					parse-error "Option --$name given more than once"
				}
				incr seen($name)
				set vars($name) $value
			} else {
				lappend vars($name) $value
			}
		} elseif {[regexp {^--(.*)} $arg -> name]} {
			# --abc
			if {![info exists boolopts($name)]} {
				if {[info exists stropts($name)]} {
					parse-error "Option --$name requires a parameter"
				}
				parse-error "Unknown option: --$name"
			}
			lassign $boolopts($name) optname optval
			set vars($optname) $optval
		} else {
			lappend nargv {*}[lrange $argv $i end]
			break
		}
	}

	#puts nargv=$nargv

	if {[llength $nargv] < [llength $named]} {
		parse-error "No value supplied for [lindex $named [llength $nargv]]"
	}
	if {!$haveargs && [llength $nargv] > [llength $named]} {
		parse-error "Too many parameters supplied"
	}

	# Assign named args
	set i 0
	foreach name $named {
		set vars($name) [lindex $nargv $i]
		incr i
	}
	# Store any leftovers in $remaining
	set remaining [lrange $nargv $i end]

	list $vars $remaining
}

# @getopt optdef &argvn
#
# optdef looks something like:
# --test --install: --no|strip --excludes:: dest source args
#
# Sets variables in the caller's scope with the names given in optdef, except
# any remaining args are left in the original argv
# Extra args are only valid if 'args' is given as the last option.
#
# If --test is set, then test=1, otherwise test=0
# If --install is specified, it is stored in $install, otherwise $install is left unset
# If --excludes is specified (multiple times, each value is stored in the list $install
# Either --strip or --nostrip can be specified as a boolean option. --strip will set strip=1,
# while --nostrip will set strip=0
# If a boolean option is specified multiple times, the last one wins
proc getopt {optdef &argv} {
	#puts [list getopt-test $optdef $argv]
	lassign [getopt-core $optdef $argv] vars argv
	foreach {name val} $vars {
		uplevel 1 [list set $name $val]
	}
}
