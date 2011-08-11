# Copyright (c) 2008 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module to merge require libs, preserving ordering and avoiding duplicates

use tsort

# Given a list: a b c, returns a list of lists with the pairs
# {a b} {a c} {b c}
#
# If there is only one element in the list, {a}, returns a singleton {a}
proc make_pairs {list} {
	set pairs {}

	# If there is only one element 
	if {[llength $list] == 1} {
		lappend pairs [lindex $list 0]
		return $pairs
	}

	for {set i 0} {$i < [llength $list]} {incr i} {
		for {set j [expr $i + 1]} {$j < [llength $list]} {incr j} {
			lappend pairs [list [lindex $list $i] [lindex $list $j]]
		}
	}
	return $pairs
}

# Merge two lists such that the overall ordering is preserved
# between the two lists

proc merge_lists {list1 list2} {
	# Need to merge the lists so that the same order is maintained
	# We can use tsort to help here
	set pairs {}
	foreach p [make_pairs $list1] {
		lappend pairs $p
	}
	foreach p [make_pairs $list2] {
		lappend pairs $p
	}

	#puts stderr pairs=[join $pairs ","]

	# Now use tsort to do a topological sort
	set newlibs [tsort $pairs]

	#puts stderr "[local_dir]: {$list1} + {$list2} => {$newlibs}"

	return $newlibs
}
