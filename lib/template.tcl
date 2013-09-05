# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides creation of a file from a template with substitution
# XXX: Should this be in the default rulebase instead?

proc apply-template {infile outfile mapping target} {
	set mapped [string map $mapping [readfile $infile]]
	set unmapped [regexp -all -inline {@[A-Za-z0-9_]+@} $mapped]
	if {[llength $unmapped]} {
		set unmapped [string map {@ ""} [lunique $unmapped]]
		user-notice [colerr purple [make-source-location $target "" ": Warning: $target has unmapped variables: $unmapped"]]
	}
	writefile $outfile $mapped\n
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
			user-notice [warning-location "Warning: Template $target with no variables, mapping all variables"]
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
				user-notice [warning-location "Warning: $target maps undefined variable $var" build.spec]
			}
			lappend mapping @$var@ [get-define $var]
		}
	}
	target [make-local $target] -inputs [make-local $src] -vars mapping $mapping -msg {note Template $targetname} -do {
		apply-template $inputs $target $mapping $targetname
	}
	Clean $target
}
