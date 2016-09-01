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
		if {[regexp {^--([^:]*)(:*)(.*)$} $i -> name colon extra]} {
			#puts "$i -> $name, [string length $colon], $extra"
			switch [string length $colon] {
				0 {
					set default 0
					if {[string match *=* $name]} {
						lassign [split $name =] name default
					}
					if {[string match *|* $name]} {
						lassign [split $name |] prefix name
						set boolopts($prefix$name) [list $name 0]
					}
					# boolopts($name) stores a list of the actual option name and the
					# value to set
					set boolopts($name) [list $name 1]
					set vars($name) $default
				}
				1 {
					set stropts($name) [list 1 $extra]
				}
				2 {
					set stropts($name) [list 2 $extra]
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

		unset -nocomplain value
		if {[regexp {^--([^=]+)=(.*)} $arg -> name value]} {
			# --abc=def
		} elseif {[regexp {^--(.*)} $arg -> name]} {
			# --abc
		} else {
			lappend nargv {*}[lrange $argv $i end]
			break
		}

		if {[exists boolopts($name)]} {
			if {[exists value]} {
				parse-error "Option --$name does not accept a parameter"
			}
			lassign $boolopts($name) optname optval
			set vars($optname) $optval
		} elseif {[exists stropts($name)]} {
			lassign $stropts($name) type extra
			if {$type == 1} {
				if {[exists value]} {
					set vars($name) $value
				} elseif {$extra ne ""} {
					set vars($name) $extra
				} else {
					parse-error "Option --$name requires a parameter"
				}
			} else {
				if {[exists value]} {
					lappend vars($name) $value
				} elseif {$extra ne ""} {
					lappend vars($name) $extra
				} else {
					parse-error "Option --$name requires a parameter"
				}
			}
		} else {
			parse-error "Unknown option: --$name"
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
# Boolean options:
#  --test
#  --no|test
#  --test=1
#  --no|test=1
#
# Single string options:
#
#  --install:
#  --install:default
#
# Multi string options:
#
#   --exclude::
#   --exclude::default
#
# Named arguments:
#
#   dest
#
# Remaining arguments:
#
#  args
#
# Sets variables in the caller's scope with the names given in optdef, except
# any remaining args are left in the original argv
# Extra args are only valid if 'args' is given as the last option.
#
# If --test is set, then test=1, otherwise test=0
# If --install is specified, it is stored in $install, otherwise $install is left unset
# If --excludes is specified (multiple times, each value is stored in the list $excludes
# Either --strip or --nostrip can be specified as a boolean option. --strip will set strip=1,
# while --nostrip will set strip=0
# If a boolean or single string option is specified multiple times, the last one wins
proc getopt {optdef &argv} {
	#puts [list getopt-test $optdef $argv]
	lassign [getopt-core $optdef $argv] vars argv
	foreach {name val} $vars {
		uplevel 1 [list set $name $val]
	}
}
