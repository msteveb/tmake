error "do not use"
# Copyright (c) 2008 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Topological Sort (tsort)

# Add an arc to the DAG
# id -> child
proc tsort_add_pair {nodesarray childrenarray id child} {
	upvar $nodesarray nodes
	upvar $childrenarray children
	set nodes($id) 0
	set nodes($child) 0

	# REVISIT: Do we need to worry about duplicates?
	lappend children($id) $child
	if {![info exists children($child)]} {
		set children($child) {}
	}
}

# DFS walk the DAG recursively
#
# Each arc traversed adds 1 to the level.
# Each node is incremented by the current level
# (thus guaranteeing that it will have a higher number than
# any of its predecessor nodes)
proc tsort_dfs_walk {nodesarray childrenarray id level} {
	upvar $nodesarray nodes
	upvar $childrenarray children

	incr level
	if {$level > 50} {
		error "Cycle in graph"
	}
	foreach child $children($id) {
		tsort_dfs_walk nodes children $child $level
	}
	incr level -1
	incr nodes($id) $level
}

# lsort command to sort array keys based on the (integer)
# array values
#
proc tsort_sort_nodes {nodesarray id1 id2} {
	upvar $nodesarray nodes
	expr {$nodes($id1) - $nodes($id2)}
}

# Topological Sort
#
# Given a list of pairs representing {from to} arcs
# of a directed, acyclic graph, returns an ordering
# of nodes (vertexes) which is topologically sorted.
#
# e.g. tsort {{b c} {a b}} will return {a b c}
#
proc tsort {pairs} {

	array set nodes {}
	array set children {}

	set extras {}

	# Create the DAG from the pairs (arcs)
	foreach pair $pairs {
		foreach {parent child} $pair break
		# Special case {a} or {a a} represents existence only
		if {$child eq "" || $parent eq $child} {
			lappend extras $parent
		} else {
			tsort_add_pair nodes children $parent $child
		}
	}

	#parray nodes
	#parray children

	set rc [catch {
		# Depth-first walk of the tree from every node
		foreach id [array names nodes] {
			tsort_dfs_walk nodes children $id 0
		}
	} error]

	if {$rc} {
		error "$error: $pairs"
	}

	# Now sort on ::node(id) to get the results
	set result [lsort -command "tsort_sort_nodes nodes" [array names nodes]]

	# Create nodes which may have no children
	foreach id $extras {
		if {![info exists nodes($id)]} {
			lappend result $id
		}
	}

	#parray nodes
	#puts $result

	return $result
}
