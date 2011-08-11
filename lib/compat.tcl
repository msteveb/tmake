# Copyright (c) 2007-2010 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module containing misc procs useful to modules
# Largely for platform compatibility

set compat(istcl) [info exists ::tcl_library]
set compat(iswin) [string equal windows $tcl_platform(platform)]

if {$compat(iswin)} {
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

# Assume that exec can return stdout and stderr
proc exec-with-stderr {args} {
	exec {*}$args 2>@1
}

if {$compat(istcl)} {
	# Tcl doesn't have the env command
	proc getenv {name args} {
		if {[info exists ::env($name)]} {
			return $::env($name)
		}
		if {[llength $args]} {
			return [lindex $args 0]
		}
		return -code error "environment variable \"$name\" does not exist"
	}
} elseif {$compat(iswin)} {
	# On Windows, backslash convert all environment variables
	# (Assume that Tcl does this for us)
	proc getenv {name args} {
		string map {\\ /} [env $name {*}$args]
	}
	# Jim uses system() for exec under mingw, so
	# we need to fetch the output ourselves
	proc exec-with-stderr {args} {
			set tmpfile /tmp/tcl.[format %05x [rand 10000]].tmp
			set rc [catch [list exec {*}$args >$tmpfile 2>&1] result]
			set result [readfile $tmpfile]
			file delete $tmpfile
			return -code $rc $result
	}
} else {
	# Jim on unix is simple
	alias getenv env
}

# In case 'file normalize' doesn't exist
#
proc file-normalize {path} {
	if {[catch {file normalize $path} result]} {
		if {$path eq ""} {
			return ""
		}
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

# If everything is working properly, the only errors which occur
# should be generated in user code (e.g. auto.def).
# By default, we only want to show the error location in user code.
# We use [info frame] to achieve this, but it works differently on Tcl and Jim.
#
# This is designed to be called for incorrect usage, via dev-error
#
proc error-location {msg} {
	if {$::tmake(debug)} {
		return -code error $msg
	}
	# Search back through the stack trace for the first error in a .def file
	for {set i 1} {$i < [info level]} {incr i} {
		if {$::compat(istcl)} {
			array set info [info frame -$i]
		} else {
			lassign [info frame -$i] info(caller) info(file) info(line)
		}
		if {[string match *.def $info(file)]} {
			return "[relative-path $info(file)]:$info(line): Error: $msg"
		}
		#puts "Skipping $info(file):$info(line)"
	}
	return $msg
}

# Similar to error-location, but called when user code generates an error
# In this case we want to show the stack trace in user code, but not in system code
# (unless --debug is enabled)
#
proc error-stacktrace {msg} {
	if {$::compat(istcl)} {
		if {[regexp {file "([^ ]*)" line ([0-9]*)} $::errorInfo dummy file line]} {
			return "[relative-path $file]:$line $msg\n$::errorInfo"
		}
		return $::errorInfo
	} else {
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
		} else {
			set prefix ""
		}

		return "${prefix}Error: $msg\n[stackdump $newstacktrace]"
	}
}

proc clock-millis {} {
	if {[catch {clock millis} result]} {
		set result [expr {[clock seconds] * 1000.0}]
	}
	return $result
}
