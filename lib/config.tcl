# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module to provide simpler conditional statements

# If 'code' is not specified, the entire file is skipped unless
# the expression is true.
#
proc do_ifconfig {name expr exprargs} {
	if {[llength $exprargs] == 0} {
		# bare 'ifconfig expr'
		do_if_else 3 $expr "" "error .skip"
		return
	}

	case [llength $exprargs] {
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
	automf_error "should be $name {expr} ?{code}? ?else {code}?"
}

proc is-defined? {name} {
	if {[info exists ::$name]} {
		if {[set ::$name] ni {"" 0}} {
			return 1
		}
	}
	return 0
}

proc ifconfig {expr args} {
	# convert the simple expression into something we can evaluate
	regsub -all {([A-Z0-9_]+)} $expr {[is-defined? \1]} tclexpr

	dputs c "ifconfig: expr='$expr' tclexpr='$tclexpr'"

	do_ifconfig ifconfig $tclexpr $args
}

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
