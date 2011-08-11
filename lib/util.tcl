proc define {name args} {
	upvar #0 $name n
	set n [join $args]
}

proc define? {name args} {
	upvar #0 $name n
	if {![info exists n] || $n eq ""} {
		set n [join $args]
	}
}

# If &n is not set or is "", sets it to $value
# Otherise appends $value with a space separator (or $space)
#
proc append-with-space {&n value {space " "}} {
	if {[info exists n] && $n ne ""} {
		append n $space $value
	} else {
		set n $value
	}
}

proc define-append {name args} {
	upvar #0 $name n
	append-with-space ::$name [join $args]
}

proc suffix {suf args} {
	lmap p [join $args] {
		append p $suf
	}
}

proc change-ext {new args} {
	lmap p [join $args] {
		set x [file rootname $p]$new
	}
}

proc prefix {pre args} {
	lmap p [join $args] {
		set x $pre$p
	}
}

# Merges target variables.
# These are stored in dictionaries, where $dict1 is the current vars
# and the new vars $dict2 need to be merged.
# Where there is no overlap, the dictionaries are simply merged.
# Where a var exists in both, the values are combined with a space separator.
proc merge-vars {dict1 dict2} {
	if {[dict size $dict2]} {
		if {[dict size $dict1] == 0} {
			return $dict2
		}
		foreach {n v} $dict2 {
			append-with-space dict1($n) $v
		}
	}
	return $dict1
}
