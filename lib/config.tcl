# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# @synopsis:
#
# Provides 'ifconfig', a mechanism for simple conditional statements based on defines.

# @config-is-defined? name
#
# Returns 1 if the define exists and is not set to "" or 0
# First checks there for CONFIG_$name, then if that is not defined,
# checks for $name
proc config-is-defined? {name} {
	if {[get-define CONFIG_$name] ni {"" 0}} {
		return 1
	}
	if {[get-define $name] ni {"" 0}} {
		return 1
	}
	return 0
}

# @ifconfig expr ?code? ?else-code?
#
# Evaluates the given expression, where each term is substituted with [config-is-defined? term].
# If 'code' is not specified and the expression is false, the rest of the file is skipped.
#
# Otherwise evaluates either 'code' or 'else-code' depending on the result of the expression.
# For example:
#
# Skip the rest of the file if 'CONFIGURED' is not defined.
## ifconfig CONFIGURED
#
# Evaluate the given code if USE_UTF8 and CONFIGURED are both defined.
## ifconfig {USE_UTF8 && CONFIGURED} {
##    ...
## }
proc ifconfig {expr args} {
	# convert the simple expression into something we can evaluate
	regsub -all {([A-Z][A-Z0-9_]*)} $expr {[config-is-defined? \1]} tclexpr

	dputs c "ifconfig: expr='$expr' tclexpr='$tclexpr'"

	tailcall do_ifconfig ifconfig $tclexpr $args
}

# Internal command.
# If 'code' is not specified, the entire file is skipped unless
# the expression is true.
#
proc do_ifconfig {name expr exprargs} {
	if {[llength $exprargs] == 0} {
		# bare 'ifconfig expr'
		tailcall do_if_else $expr "" "return -code 20 skip"
	}

	switch -exact [llength $exprargs] {
		1 {
			# ifconfig expr {code}
			tailcall do_if_else $expr [lindex $exprargs 0] ""
		}
		3 {
			# ifconfig expr {code} else {code}
			if {[lindex $exprargs 1] eq "else"} {
				tailcall do_if_else $expr [lindex $exprargs 0] [lindex $exprargs 2]
			}
		}
	}
	parse-error "ifconfig: should be $name {expr} ?{code}? ?else {code}?"
}


# Internal command to implement ifconfig
#
proc do_if_else {expr true false} {
	if $expr {
		dputs c "Expression is true, so executing $true"
		if {$true ne ""} {
			tailcall eval $true
		}
	} else {
		dputs c "Expression is false"
		if {$false ne ""} {
			tailcall eval $false
		}
	}
}
