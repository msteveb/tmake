# Copyright (c) 2007 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module containing misc procs useful to modules

# Returns a new list with quotes, backslashes and spaces escaped (with backslash)
# Note that we double escape everything. Once for the shell and once for the C compiler
proc escape_flags {inflags} {
	set flags {}
	foreach a $inflags {
		set a [string map $::escape_map $a]
		lappend flags $a
	}
	return $flags
}

set ::escape_map {}
lappend ::escape_map \\
lappend ::escape_map \\\\

lappend ::escape_map {"}
lappend ::escape_map {\\\"}

lappend ::escape_map " "
lappend ::escape_map {\\\ }

lappend ::escape_map {(}
lappend ::escape_map {\\\(}

lappend ::escape_map {)}
lappend ::escape_map {\\\)}

# Given a glob patterns, returns a list of matching
# files in the current dir ([local_dir])
proc glob_local {pattern} {
	set result {}
	foreach p [glob [local_dir]/$pattern] {
		lappend result [file tail $p]
	}
	return $result
}

# Tcl doesn't have the env command
if {[info command env] eq ""} {
	proc env {args} {
		if {[llength $args] == 0} {
			return [array get ::env]
		}
		set var [lindex $args 0]
		if {[info exists ::env($var)]} {
			return $::env($var)
		}
		if {[llength $args] > 1} {
			return [lindex $args 1]
		}
		return -code error "environment variable \"$var\" does not exist"
	}
}

if {[catch {clock millis}]} {
	proc clock-millis {} {
		expr {[clock seconds] * 1000.0}
	}
} else {
	proc clock-millis {} {
		clock millis
	}
}
