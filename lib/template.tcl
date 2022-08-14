# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides creation of a file from a template with substitution
# XXX: Should this be in the default rulebase instead?

# @apply-template infile outfile vars targetname
#
# Reads the input file '$infile' and writes the output file '$outfile'
#
# '$vars' contains a list of variable name value pairs
#
# '$targetname' is the name of the output file for warning reporting purposes.
#
# If '$outfile' is blank/omitted, '$template' should end with '.in' which
# is removed to create the output file name.
#
# Conditional sections may be specified as follows:
## @if NAME eq "value"
## lines
## @else
## lines
## @endif
#
# Where 'NAME' is a variable name from '$vars' and '@else' is optional.
# If the expression does not match, all lines through '@endif' are ignored.
#
# The alternative forms may also be used:
## @if NAME  (true if the variable is defined, but not empty and not "0")
## @if !NAME  (opposite of the form above)
## @if <general-tcl-expression>
#
# In the general Tcl expression, any words beginning with an uppercase letter
# are translated into the [dict get $vars NAME]
#
# Expressions may be nested
#
proc apply-template {infile outfile vars target} {

	dputs m "apply-template $infile -> $outfile: vars=$vars"

	# A stack of true/false conditions, one for each nested conditional
	# starting with "true"
	set condstack {1}
	set result {}
	set linenum 0
	foreach line [split [readfile $infile] \n] {
		incr linenum
		if {[regexp {^@(if|else|endif)\s*(.*)} $line -> condtype condargs]} {
			if {$condtype eq "if"} {
				if {[llength $condargs] == 1} {
					# ABC => [dict get $vars ABC] ni {0 ""}
					# !ABC => [dict get $vars ABC] in {0 ""}
					lassign $condargs condvar
					set not 0
					if {[regexp {^!(.*)} $condvar -> condvar]} {
						set not 1
					}
					if {![dict exists $vars $condvar]} {
						build-fatal-error "$infile:$linenum: Error: No such variable: $condvar"
					}
					set value [dict get $vars $condvar]
					set condexpr 0
					if {$not} {
						if {$value in {0 ""}} {
							set condexpr 1
						}
					} else {
						if {$value ni {0 ""}} {
							set condexpr 1
						}
					}
				} else {
					# Translate alphanumeric ABC into [dict get $vars ABC] and leave the
					# rest of the expression untouched
					regsub -all {([A-Z][[:alnum:]_]*)} $condargs {[dict get \$vars \1]} condexpr
				}
				if {[catch [list expr $condexpr] condval]} {
					dputs m $condval
					build-fatal-error "$infile:$linenum: Error: Invalid expression: $line"
				}
				dputs m "$infile:$linenum: @$condtype $condargs ($condexpr) => $condval"
			}
			if {$condtype ne "if" && [llength $condstack] <= 1} {
				build-fatal-error "$infile:$linenum: Error: @$condtype missing @if"
			}
			switch -exact $condtype {
				if {
					# push condval
					lappend condstack $condval
				}
				else {
					# Toggle the last entry
					set condval [lpop condstack]
					set condval [expr {!$condval}]
					lappend condstack $condval
				}
				endif {
					if {[llength $condstack] == 0} {
						user-notice "$infile:$linenum: Error: @endif missing @if"
					}
					lpop condstack
				}
			}
			continue
		}
		# Only output this line if the stack contains all "true"
		if {"0" in $condstack} {
			continue
		}
		lappend result $line
	}

	# Now the inline mapping
	set mapping {}
	foreach {name value} $vars {
		lappend mapping @$name@ $value
	}

	# Apply the mapping
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
# Returns the local target to allow the following construct:
#
# Depends all [Template target src ...]
#
rule Template {args} {
Template ?--nowarn? target src ?var1 var2 var3=value ...?

Creates 'target' from 'src' substituting @var1@, @var2@, etc. with
the value of the corresponding defined variables, or the given value.

Also supports conditionals, @if, @else and @endif. See 'apply-template' in the tmake reference.

Note: If no variables are specified, all defined variables will be mapped but this is not recommended
and produces a warning unless '--nowarn' is given.
} {
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
	set vars {}
	foreach var $args {
		if {[regexp {([^=]*)=(.*)} $var -> name value]} {
			lappend vars $name $value
		} else {
			if {![define-exists $var]} {
				user-notice purple [warning-location "Warning: $target maps undefined variable $var"]
			}
			lappend vars $var [get-define $var]
		}
	}
	target [make-local $target] -inputs [make-local $src] -vars vars $vars -msg {note Template $targetname} -do {
		apply-template $inputs $target $vars $targetname
	}
	Clean $target
	return [make-local $target]
}
