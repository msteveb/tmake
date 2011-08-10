# Contains custom validation for various types

# REVISIT: Need a newer version of jim to get 'string is'
proc string_is_int {n} {
	#string is integer -strict $n
	catch -noreturn {
		if {$n + 0 == $n} {
			return 1
		}
	}
	return 0
}

# Each element must be one
proc is_valid_listof {value types} {
	foreach s [split $value] {
		if {$s eq ""} {
			continue
		}
		set errors {}
		foreach type $types {
			set e [is_valid_$type $s]
			if {$e eq ""} {
				incr ok
				set errors {}
				break
			} else {
				lappend errors $e
			}
		}
		if {$errors ne ""} {
			return $errors
		}
	}
}

proc is_valid_ipaddr {value {dummy {}}} {
	set i 0
	foreach octet [split $value .] {
		if {![string_is_int $octet] || $octet < 0 || $octet > 255} {
			set i 0
			break
		}
		incr i
	}
	if {$i != 4} {
		return "Not a valid IP address: $value"
	}
}

proc is_valid_hostname {value {dummy {}}} {
	set ok 0
	set i 0
	foreach part [split $value .] {
		if {![regexp {^[a-zA-Z0-9][a-zA-Z0-9-]*$} $part]} {
			set ok 0
			break
		}
		# Only the first part can start with a digit.
		# It can't end with a hyphen
		if {($i != 0 && [string match {[0-9]*} $part]) || [string match *- $part]} {
			set ok 0
			break
		}
		set ok 1
		incr i
	}
	if {!$ok} {
		return "Not a valid hostname: $value"
	}
}

#is_valid_listof "1.2.3.4 5.6.7.8  this.is.a.test" {ipaddr hostname}
#puts [is_valid_hostname 1.2.3.4]
#puts [is_valid_hostname 1.a.b.c]
#puts [is_valid_hostname 1.a-.b.c]
#puts [is_valid_hostname 1.a-b.b.c]
