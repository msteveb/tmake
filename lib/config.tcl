# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# @synopsis:
#
# Provides 'ifconfig', a mechanism for simple conditional statements based on defines.

# @is-defined? name
#
# Returns 1 if the define exists and is not set to "" or 0
proc is-defined? {name} {
	if {[get-define $name] ni {"" 0}} {
		return 1
	}
	return 0
}

# @ifconfig expr ?code? ?else-code?
#
# Evaluates the given expression, where each term is substituted with [is-defined? term].
# If 'code' is not specified and the expression is false, the rest of the file is skipped.
#
# Otherwise evaluates either 'code' or 'else-code' depending on the result of the expression.
# For example:
#
# Skip the rest of the file if 'CONFIGURED' is not defined.
## ifconfig CONFIGURED
#
# Evaluate the given code if USE_UTF8 and CONFIGURED are both defined.
## ifconfig USE_UTF8 && CONFIGURED {
##    ...
## }
proc ifconfig {expr args} {
	# convert the simple expression into something we can evaluate
	regsub -all {([A-Z][A-Z0-9_]*)} $expr {[is-defined? \1]} tclexpr

	dputs c "ifconfig: expr='$expr' tclexpr='$tclexpr'"

	do_ifconfig ifconfig $tclexpr $args
}

# Internal command.
# If 'code' is not specified, the entire file is skipped unless
# the expression is true.
#
proc do_ifconfig {name expr exprargs} {
	if {[llength $exprargs] == 0} {
		# bare 'ifconfig expr'
		do_if_else 3 $expr "" "return -code 20 skip"
		return
	}

	switch -exact [llength $exprargs] {
		1 {
			# ifconfig expr {code}
			do_if_else 3 $expr [lindex $exprargs 0] ""
			return
		}
		3 {
			# ifconfig expr {code} else {code}
			if {[lindex $exprargs 1] == "else"} {
				do_if_else 3 $expr [lindex $exprargs 0] [lindex $exprargs 2] 
				return
			}
		}
	}
	parse-error "ifconfig: should be $name {expr} ?{code}? ?else {code}?"
}


# Internal command to implement ifconfig
#
proc do_if_else {level expr true false} {
	if $expr {
		dputs c "Expression is true, so executing $true"
		if {$true != ""} {
			uplevel $level $true
		}
	} else {
		dputs c "Expression is false"
		if {$false != ""} {
			uplevel $level $false
		}
	}
}
