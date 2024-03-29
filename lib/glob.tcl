# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides local-aware file globbing

# Patterns are file patterns actual paths, typically created by make-local-src
# If $all is true, non-patterns are returned as-is
proc glob-nonrecursive {patterns all {istype isfile} {exclude {}}} {
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
		foreach path [glob -nocomplain $globpattern] {
			if {[file $istype $path] && [file tail $path] ni $exclude} {
				lappend result $path
			}
		}
	}

	return $result
}

# Patterns are file patterns actual paths, typically created by make-local-src
proc glob-recursive {patterns type {exclude {}}} {
	set result {}

	foreach pattern $patterns {
		# Split the pattern into the directory part and the pattern part
		set dirpattern [file dirname $pattern]
		set tailpattern [file tail $pattern]

		# Find all directories which match the directory pattern
		foreach dir [glob-nonrecursive $dirpattern 0 isdir $exclude] {
			lappend result {*}[glob-recursive [file-join $dir/* $tailpattern] $type $exclude]
			lappend result {*}[glob-nonrecursive [file-join $dir $tailpattern] 0 $type $exclude]
		}
	}
	return $result
}

# @Glob ?--warn? ?--dirs? ?--all? ?--recursive? ?--exclude=filename? pattern ...
#
# Returns "local" filenames matching the given pattern(s).
# The pattern may include a path/directory pattern.
#
## --warn       produces a warning if no files matched any pattern
## --dirs       returns directories matching the given pattern(s). otherwise only files.
## --all        patterns that don't match any files are returned as-is instead of no result.
## --recursive  recurse into subdirectories
## --exclude    exclude results matching the given filename (may be specified more than once)
#
# Examples:
#
# Return all .test files:
#
## Glob *.test
#
# Return all .c files any directory below test.*, including ignore.c:
#
## Glob --recursive --exclude=ignore.c test.*/*.c
#
proc Glob {args} {
	show-this-rule

	set exclude {}
	getopt {--warn --dirs --all --recursive --exclude:: args} args

	# Any args which are already absolute paths shouldn't have make-local-src applied
	set args [join $args]

	set patterns {}
	set pwd [pwd]
	foreach pattern $args {
		if {[file join $pwd $pattern] eq $pattern} {
			parse-error "Glob $pattern is not a (source) relative path. Try \[glob\]"
		}
	}
	set patterns [make-local-src {*}$args]

	if {$dirs} {
		set type exists
	} else {
		set type isfile
	}

	if {$recursive} {
		set paths [glob-recursive $patterns $type $exclude]
	} else {
		set paths [glob-nonrecursive $patterns $all $type $exclude]
	}

	if {[llength $paths]} {
		set paths [make-unlocal-src {*}$paths]
	} else {
		if {$warn} {
			user-notice "Warning: No matches for Glob $patterns"
		}
	}

	lsort $paths
}
