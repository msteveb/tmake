# Copyright (c) 2007-2010 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module containing misc procs useful to modules
# Largely for platform compatibility

set tmakecompat(iswin) [string equal windows $tcl_platform(platform)]

if {$tmakecompat(iswin)} {
	# mingw/windows separates $PATH with semicolons
	# and doesn't have an executable bit
	proc split-path {} {
		split [getenv PATH .] {;}
	}
	proc file-isexec {exec} {
		# Basic test for windows. We ignore .bat
		if {[file isfile $exec] || [file isfile $exec.exe]} {
			return 1
		}
		return 0
	}
} else {
	# unix separates $PATH with colons and has and executable bit
	proc split-path {} {
		split [getenv PATH .] :
	}
	proc file-isexec {exec} {
		file executable $exec
	}
}

if {$tmakecompat(iswin)} {
	# On Windows, backslash convert all environment variables
	# (Assume that Tcl does this for us)
	proc getenv {name args} {
		string map {\\ /} [env $name {*}$args]
	}
	proc exec-save-stderr {args} {
		# If the command is a shell script, we need to manually implement #!/bin/sh
		# by running "sh script ..."
		set scriptargs [lassign $args script]
		if {[file exists $script]} {
			set f [open $script]
			if {[gets $f buf] > 0} {
				if {[regexp {^#!([^ ]*)(.*)$} $buf -> cmd cmdargs]} {
					set args [list [file tail $cmd] {*}$cmdargs {*}$args]
				}
			}
			close $f
		}
		exec >@stdout {*}$args
	}
} else {
	# Jim on unix is simple
	alias getenv env
	proc exec-save-stderr {args} {
		exec >@stdout {*}$args
	}
}
proc env-save {} {
	return $::env
}
alias array-set set
proc env-restore {newenv} {
	set ::env $newenv
}
proc lunique {list} {
	set a {}
	foreach i $list {
		set a($i) 1
	}
	lsort [dict keys $a]
}
proc isatty? {channel} {
	set tty 0
	catch {
		# isatty is a recent addition to Jim Tcl
		set tty [$channel isatty]
	}
	return $tty
}

proc getenv {name args} {
	if {[info exists ::env($name)]} {
		set value $::env($name)
	} elseif {[llength $args]} {
		set value [lindex $args 0]
	} else {
		return -code error "environment variable \"$name\" does not exist"
	}
	if {$::tmakecompat(iswin)} {
		# On Windows, backslash convert all environment variables
		# (Assume that Tcl does this for us)
		set value [string map {\\ /} $value]
	}
	return $value
}

proc setenv {name value} {
	set ::env($name) $value
}


# Jim Tcl can't normalize a non-existent path
proc file-normalize {path} {
	if {$path eq ""} {
		return ""
	}
	if {[catch {file normalize $path} result]} {
		set oldpwd [pwd]
		if {[file isdir $path]} {
			cd $path
			set result [pwd]
		} else {
			cd [file dirname $path]
			set result [file join [pwd] [file tail $path]]
		}
		cd $oldpwd
	}
	return $result
}

proc file-join {dir path} {
	if {$dir eq "."} {
		return $path
	}
	if {$path eq "."} {
		return $dir
	}
	file join $dir $path
}

##################################################################
#
# Directory/path handling
#

proc realdir {dir} {
	set oldpwd [pwd]
	cd $dir
	set pwd [pwd]
	cd $oldpwd
	return $pwd
}

# Follow symlinks until we get to something which is not a symlink
proc realpath {path} {
	while {1} {
		if {[catch {
			set path [file link $path]
		}]} {
			# Not a link
			break
		}
	}
	return $path
}

# Convert absolute path, $path into a path relative
# to the given directory (or the current dir, if not given).
#
proc relative-path {path {pwd {}}} {
	if {![file exists $path]} {
		stderr puts "Warning: $path does not exist. May not be canonical"
	} else {
		set path [file-normalize $path]
	}
	if {$pwd eq ""} {
		set pwd [pwd]
	} else {
		set pwd [file-normalize $pwd]
	}

	if {$path eq $pwd} {
		return .
	}

	set splitpath [split $path /]
	set splitpwd [split $pwd /]

	# Count the number of identical levels
	# The first level will always match
	set n 0
	foreach i $splitpath j $splitpwd {
		if {$i ne $j} {
			#puts "Not equal, so stripping $n levels"
			set splitpath [lrange $splitpath $n end]
			set splitpwd [lrange $splitpwd $n end]
			break
		}
		incr n
		continue
	}
	if {$n == 1} {
		return $path
	}
	if {[llength $splitpwd]} {
		set relpath [lrepeat [llength $splitpwd] ..]
	}
	lappend relpath {*}$splitpath

	join $relpath /
}

# If everything is working properly, the only errors which occur
# should be generated in user code (e.g. auto.def).
# By default, we only want to show the error location in user code.
# We use [info frame] to achieve this, but it works differently on Tcl and Jim.
#
# This is designed to be called for incorrect usage, via dev-error
#
proc error-location {msg} {
	if {$::tmake(debug)} {
		return [error-stacktrace $msg]
	}
	warning-location $msg
}

# warning-location is like error-location except
# it does not show a stack trace, even when debugging is enabled
#
proc warning-location {msg {pattern *.spec}} {
	set loc [find-source-location $pattern]
	if {$loc ne "unknown"} {
		return "$loc: $msg"
	}
	return $msg
}

# Look down the stack frame for the first location
# which is in a file matching the pattern and return it as file:line
# Returns "unknown" if not known.
#
proc find-source-location {{pattern *.spec}} {
	# Search back through the stack for the first location in a .spec file
	for {set i 1} {$i < [info level]} {incr i} {
		lassign [info frame -$i] info(caller) info(file) info(line)
		if {[string match $pattern $info(file)]} {
			return [relative-path $info(file)]:$info(line)
		}
	}
	return unknown
}

# Similar to error-location, but called when user code generates an error
# In this case we want to show the stack trace in user code, but not in system code
# (unless --debug is enabled)
#
proc error-stacktrace {msg} {
	# Prepend a live stacktrace to the error stacktrace, omitting the current level
	set stacktrace [concat [info stacktrace] [lrange [stacktrace] 3 end]]

	if {!$::tmake(debug)} {
		# Only keep levels from *.spec files or with no file
		set newstacktrace {}
		foreach {p f l} $stacktrace {
			if {![string match "*.spec" $f] || $f eq ""} {
				#puts "Skipping $p $f:$l"
				continue
			}
			lappend newstacktrace $p $f $l
		}
		set stacktrace $newstacktrace
	}

	# Convert filenames to relative paths
	set newstacktrace {}
	foreach {p f l} $stacktrace {
		lappend newstacktrace $p [relative-path $f] $l
	}
	lassign $newstacktrace p f l
	if {$f ne ""} {
		set prefix "$f:$l: "
		set newstacktrace [lrange $newstacktrace 3 end]
	} else {
		set prefix ""
	}

	return "${prefix}Error: $msg\n[stackdump $newstacktrace]"
}

# Do we have the two-argument [source]?
if {[catch {source filename {}}]} {
	proc source-eval {filename args} {
		if {[llength $args]} {
			tailcall eval {*}$args
		} else {
			tailcall source $filename
		}
	}
} else {
	alias source-eval source
}

alias clock-millis clock millis

signal ignore SIGINT SIGTERM
proc check-signal {{clear 0}} {
	if {$clear} {
		set clear -clear
	} else {
		set clear ""
	}
	if {[signal check {*}$clear] ne ""} {
		return 1
	}
	return 0
}
