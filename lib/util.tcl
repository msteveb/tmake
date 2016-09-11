# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which contains miscellaneous utility functions

# Dump variables in the parent scope to stdout
proc dump-vars {{maxlength 50}} {
	set vars [uplevel 1 info vars]
	foreach v [lsort $vars] {
		set value [uplevel 1 [list set $v]]
		set value [string map [list \\ \\\\ \n \\n] $value]
		if {[string length $value] > $maxlength} {
			set value [string range $value 0 $maxlength]...
		}
		puts "\$[set v] = $value"
	}
}

# @compare-versions version1 version2
#
# Versions are of the form a.b.c (may be any number of numeric components)
#
# Compares the two versions and returns:
## -1 if v1 < v2
##  0 if v1 == v2
##  1 if v1 > v2
#
# If one version has fewer components than the other, 0 is substituted. e.g.
## 0.2   <  0.3
## 0.2.5 >  0.2
## 1.1   == 1.1.0
#
proc compare-versions {v1 v2} {
	foreach c1 [split $v1 .] c2 [split $v2 .] {
		if {$c1 eq ""} {
			set c1 0
		}
		if {$c2 eq ""} {
			set c2 0
		}
		if {$c1 < $c2} {
			return -1
		}
		if {$c1 > $c2} {
			return 1
		}
	}
	return 0
}

proc pad {text width {char { }}} {
	if {[string length $text] >= $width} {
		return $text
	}
	return $text[string repeat $char [expr {$width - [string length $text]}]]
}

# If the given var is not set or is "", sets it to $value
# Otherise appends $value with a space separator (or $space)
#
proc append-with-space {varname value {space " "}} {
	upvar $varname n
	if {[info exists n] && $n ne ""} {
		append n $space $value
	} else {
		set n $value
	}
}

# Takes a list and returns a new list with $suf appended
# to each element
# 
# suffix .c a b c => a.c b.c c.c
#
proc suffix {suf args} {
	set result {}
	foreach p [join $args] {
		lappend result $p$suf
	}
	return $result
}

# Takes a list and returns a new list with $pre prepended
# to each element
# 
# prefix jim- a.c b.c => jim-a.c jim-b.c
#
proc prefix {pre args} {
	set result {}
	foreach p [join $args] {
		lappend result $pre$p
	}
	return $result
}

# @omit list elements..
#
# Returns a list with the given elements removed
proc omit {list args} {
	lmap p $list {
		if {$p in $args} {
			continue
		}
		lindex $p
	}
}

# Takes a list of filenames and returns a new list with
# the extension of each filename changed to $ext
# 
# change-ext .c a.o b.o c => a.c b.c c.c
#
proc change-ext {ext args} {
	set result {}
	foreach p [join $args] {
		lappend result [file rootname $p]$ext
	}
	return $result
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
		set d1 $dict1
		foreach {n v} $dict2 {
			append-with-space d1($n) $v
		}
		return $d1
	}
	return $dict1
}
