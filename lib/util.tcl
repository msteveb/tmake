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

