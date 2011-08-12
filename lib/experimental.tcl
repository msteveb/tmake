error "do not use"
# ==================================================================
# Experimental
# ==================================================================

proc ifconfig {symbol {code {}} {else {}} {elsecode {}}} {
	global $symbol
	if {$else ni {"" else}} {
		error "Usage: ifconfig symbol ?code? ?else code?"
	}
	if {[info exists $symbol]} {
		if {[set $symbol] ni {"" 0}} {
			uplevel 1 $code
			return 1
		}
	}
	if {$else eq "else"} {
		uplevel 1 $elsecode
	}
	return 0
}

