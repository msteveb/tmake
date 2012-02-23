# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# File globbing

proc globputs {msg} {
	#puts $msg
}

# Patterns are local-src patterns
proc glob-nonrecursive {patterns all {types file} {exclude {}}} {
	set result {}

	# Optimise the common case
	if {$all && ![string match {*[{}*?]*} $patterns] && $exclude eq {}} {
		return [join $patterns]
	}

	foreach pattern $patterns {
		# Use --all to ensure that non-patterns aren't silently removed
		if {$all && ![string match {*[{}*?]*} $pattern]} {
			lappend result $pattern
			continue
		}
		set globpattern $pattern
		globputs "glob -nocomplain $globpattern => [glob -nocomplain $globpattern]"
		foreach path [glob -nocomplain $globpattern] {
			# XXX: Can we exclude here? Based on dir? tail? other?
			if {[file type $path] in $types && [file tail $path] ni $exclude} {
				lappend result $path
			}
		}
	}

	globputs "glob-nonrecursive: $patterns => [lsort $result]"
	return $result
}

proc glob-recursive {patterns {exclude {}}} {
	set result {}

	foreach pattern $patterns {
		# Split the pattern into the directory part and the pattern part
		set dirpattern [file dirname $pattern]
		set tailpattern [file tail $pattern]

		#puts "got $pattern => dirpattern=$dirpattern, tailpattern=$tailpattern"
		#puts "Finding directories for $dirpattern => [glob-nonrecursive $dirpattern 0 directory $exclude]"

		# Find all directories which match the directory pattern
		foreach dir [glob-nonrecursive $dirpattern 0 directory $exclude] {
			globputs "Recursing for [file-join $dir $tailpattern]"
			lappend result {*}[glob-recursive [file-join $dir/* $tailpattern] $exclude]
			#globputs "Now checking $dir for files matching $tailpattern"
			lappend result {*}[glob-nonrecursive [file-join $dir $tailpattern] 0 file $exclude]
		}
	}
	globputs "glob-recursive $patterns => [lsort $result]"
	return $result
}

proc Glob {args} {
	show-this-rule

	globputs "\n\nIn [local-dir], Glob $args"

	getopt {--warn --all --recursive --exclude:: args} args

	#puts "In [local-dir]: Glob $args => "

	set args [make-local-src {*}[join $args]]

	globputs " -- local-src args = $args"

	#globputs "\n\nIn [local-dir], about to glob $args"

	if {$recursive} {
		set paths [glob-recursive $args $exclude]
	} else {
		set paths [glob-nonrecursive $args $all file $exclude]
	}

	if {[llength $paths]} {
		set paths [make-unlocal-src {*}$paths]
		globputs " => [lsort $paths]"
	} else {
		if {$warn} {
			user-notice "Warning: No matches for Glob $args"
		}
	}

	lsort $paths
}
