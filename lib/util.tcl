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
