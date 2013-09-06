# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides creation of a file from a template with substitution
# XXX: Should this be in the default rulebase instead?

# @apply-template infile outfile mapping targetname
#
# Reads the input file $infile and writes the output file $outfile.
#
# $mapping is a mapping per [string map]
#
# $targetname is the name of the output file for warning reporting purposes.
#
# Conditional sections may be specified as follows:
## @if name == value
## lines
## @else
## lines
## @endif
#
# Where 'name' is a defined variable name and @else is optional.
# If the expression does not match, all lines through '@endif' are ignored.
#
# The alternative forms may also be used:
## @if name
## @if name != value
#
# Where the first form is true if the variable is defined, but not empty or 0
#
# Currently these expressions can't be nested.
#
proc apply-template {infile outfile mapping target} {
	set mapped [string map $mapping [readfile $infile]]


	set result {}
	foreach line [split [readfile $infile] \n] {
		if {[info exists cond]} {
			set l [string trimright $line]
			if {$l eq "@endif"} {
				unset cond
				continue
			}
			if {$l eq "@else"} {
				set cond [expr {!$cond}]
				continue
			}
			if {$cond} {
				lappend result $line
			}
			continue
		}
		if {[regexp {^@if\s+(\w+)(.*)} $line -> name expression]} {
			lassign $expression equal value
			set varval [get-define $name ""]
			if {$equal eq ""} {
				set cond [expr {$varval ni {"" 0}}]
			} else {
				set cond [expr {$varval eq $value}]
				if {$equal ne "=="} {
					set cond [expr {!$cond}]
				}
			}
			continue
		}
		lappend result $line
	}
	set mapped [string map $mapping [join $result \n]]\n
	# Check for any unmapped variables
	set unmapped [regexp -all -inline {@[A-Za-z0-9_]+@} $mapped]
	if {[llength $unmapped]} {
		set unmapped [string map {@ ""} [lunique $unmapped]]
		user-notice purple [make-source-location $target "" ": Warning: $target has unmapped variables: $unmapped"]
	}
	writefile $outfile $mapped
}

# Note that it is possible to omit any mapping, in
# which case all defined variables are mapped.
# This is not recommended since any change to a variable will cause
# the template to be regenerated.
#
proc Template {args} {
	show-this-rule

	getopt {--nowarn target src args} args

	if {[llength $args] == 0} {
		# This is more of a hint than a warning
		if {!$nowarn} {
			user-notice purple [warning-location "Warning: Template $target with no variables, mapping all variables"]
		}
		set args [lsort [dict keys $::tmake(defines)]]
	}

	# Create the mapping as a variable to the rule.
	# If the mapping changes, the rule will re-run
	#       
	set mapping {}
	foreach var $args {
		if {[regexp {([^=]*)=(.*)} $var -> name value]} {
			lappend mapping @$name@ $value
		} else {
			if {![define-exists $var]} {
				user-notice purple [warning-location "Warning: $target maps undefined variable $var" build.spec]
			}
			lappend mapping @$var@ [get-define $var]
		}
	}
	target [make-local $target] -inputs [make-local $src] -vars mapping $mapping -msg {note Template $targetname} -do {
		apply-template $inputs $target $mapping $targetname
	}
	Clean $target
}
