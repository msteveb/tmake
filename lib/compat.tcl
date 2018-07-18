# Copyright (c) 2007-2010 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# @synopsis:
#
# Module containing misc procs useful to modules, 
# largely for platform compatibility.

if {[string equal windows $tcl_platform(platform)]} {
	proc iswin {} { return 1 }
} else {
	proc iswin {} { return 0 }
}

# @file-isexec filename
#
# Implements 'file isexec'

# @exec-save-stderr cmd ...
#
# Implements 'exec >@stdout ...' to capture and return stderr on platforms
# that don't support this natively.

if {[iswin]} {
	# mingw/windows doesn't have an executable bit so use a heuristic
	proc file-isexec {exec} {
		# Basic test for windows. We ignore .bat
		if {[file isfile $exec] || [file isfile $exec.exe]} {
			return 1
		}
		return 0
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
	# minw32 seems to use full buffering for stderr
	stdout buffering line
	stderr buffering none
} else {
	# unix separates $PATH with colons and has and executable bit
	proc file-isexec {exec} {
		file executable $exec
	}
	proc exec-save-stderr {args} {
		exec >@stdout {*}$args
	}
}


# @split-path
#
# Returns environment variable $PATH as a list
#
proc split-path {} {
	split [getenv PATH .] $::tcl_platform(pathSeparator)
}

# @lunique list
#
# Returns a copy of $list with any duplicates removed.
# The list is returned in 'lsort' order.
#
proc lunique {list} {
	set a {}
	foreach i $list {
		set a($i) 1
	}
	lsort [dict keys $a]
}

# @isatty? channel
#
# Returns 1 if the channel is a tty. 
#
proc isatty? {channel} {
	set tty 0
	catch {
		# isatty is a recent addition to Jim Tcl
		set tty [$channel isatty]
	}
	return $tty
}

# Returns a dictionary containing the current environment
proc env-save {} {
	return $::env
}

# Sets the current environment to the given dictionary
proc env-restore {newenv} {
	set ::env $newenv
}

# @getenv name ?default?
#
# Returns the value of environment variable 'name'.
# If not set, returns 'default' if specified, otherwise generates an error.
#
# Note that on Windows, all environment variable values have backslash
# converted to forward slash automatically.
proc getenv {name args} {
	if {[info exists ::env($name)]} {
		set value $::env($name)
	} elseif {[llength $args]} {
		set value [lindex $args 0]
	} else {
		return -code error "environment variable \"$name\" does not exist"
	}
	if {[iswin]} {
		# On Windows, backslash convert all environment variables
		set value [string map {\\ /} $value]
	}
	return $value
}

# @setenv name value
#
# Sets the value of the given environment variable
#
proc setenv {name value} {
	set ::env($name) $value
}


# @file-normalize path
#
# Like 'file normalize', but follows symlinks and is supported even on 
# platforms withouth 'file normalize'
#
proc file-normalize {path} {
	if {$path eq ""} {
		return ""
	}
	while {[file exists $path] && [file type $path] eq "link"} {
		set path [file readlink $path]
	}
	if {[catch {file normalize $path} result]} {
		# If file normalize isn't support, use cd/pwd
		# This requires the path to exist
		set oldpwd [pwd]
		if {[file isdir $path]} {
			cd $path
			set result [pwd]
		} else {
			file mkdir [file dirname $path]
			cd [file dirname $path]
			set result [file join [pwd] [file tail $path]]
		}
		cd $oldpwd
	}
	return $result
}

# @file-join dir path
#
# Like 'file join' except will omit "." in either 'dir' or 'path'
# e.g.
#
## file-join . abc => abc
## file-join abc/def . => abc/def
## file-join abc/def ghi => abc/def/ghi
proc file-join {dir path} {
	if {$dir eq "."} {
		return $path
	}
	if {$path eq "."} {
		return $dir
	}
	file join $dir $path
}

# @file-link ?-symbolic|-hard? newname target
#
# Implements 'file link', but uses the external command 'ln' if
# 'file link' is not supported internally.
#
# Note that the arguments are reversed from 'ln', so creates 
# 'dest' -> 'target'
if {"link" in [file -commands]} {
	alias file-link file link
} else {
	proc file-link {{-symbolic|-hard -hard} newname target} {
		set opt ${-symbolic|-hard}
		switch -glob -- $opt {
			-h* {
				exec ln $target $newname
			}
			-s* {
				exec ln -s $target $newname
			}
			default {
				return -code error "bad option \"$opt\": must be -hard, or -symbolic"
			}
		}
	}
}

# @file-mtime filename
#
# Implements 'file mtime', or 'file mtimens' if supported.
#
if {"mtimens" in [file -commands]} {
	alias file-mtime file mtimens
} else {
	alias file-mtime file mtime
}

# Implements 'wait' in terms of the older 'os.wait'
#
if {![exists -command wait]} {
	proc wait {args} {
		lassign [os.wait {*}$args] pid status rc
		switch -exact -- $status {
			error - none {
				set status NONE
			}
			exit {
				set status CHILDSTATUS
			}
			signal {
				set status CHILDKILLED
			}
			other {
				set status CHILDSUSP
			}
		}
		list $status $pid $rc
	}
}

##################################################################
#
# Directory/path handling
#

# @relative-path path ?pwd?
#
# Convert absolute path 'path' into a path relative
# to 'pwd', (or the current directory, if not given).
#
proc relative-path {path {pwd {}}} {
	if {![string match /* $path]} {
		if {![file exists $path]} {
			stderr puts "Warning: $path does not exist. May not be canonical"
		} else {
			set path [file-normalize $path]
		}
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
# We use [info frame] to achieve this.
#
# This is designed to be called for incorrect usage, via parse-error
#
proc error-location {msg} {
	if {$::tmake(debug)} {
		tailcall error-stacktrace $msg
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
	puts "warning-location: no location found"
	return $msg
}

# Look down the stack frame for the first location
# which is in a file matching the pattern and return it as file:line
# Returns "unknown" if not known.
#
proc find-source-location {{pattern *.spec}} {
	# Search back through the stack for the first location in a .spec file
	set result unknown

	for {set i 1} {$i < [info level]} {incr i} {
		lassign [info frame -$i] info(caller) info(file) info(line)
		if {[string match *.spec $info(file)]} {
			return [relative-path $info(file)]:$info(line)
		}
		# But use the last occurrence when searching in (e.g.) rulebase.default
		if {[string match $pattern $info(file)]} {
			set result $info(file):$info(line)
		}
	}
	return $result
}

# Similar to error-location, but called when user code generates an error
# In this case we want to show the stack trace in user code, but not in system code
# (unless --debug is enabled)
#
proc error-stacktrace {msg {stacktrace {}}} {
	if {$::tmake(debug)} {
		# In debug mode, prepend a live stacktrace to the error stacktrace, omitting the current level
		lappend stacktrace {*}[lrange [stacktrace] 3 end]
	}

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
		if {$f ne "" && [file exists $f]} {
			set f [relative-path $f]
		}
		lappend newstacktrace $p $f $l
	}
	lassign $newstacktrace p f l
	if {$f ne ""} {
		set prefix "$f:$l: "
		set newstacktrace [lrange $newstacktrace 3 end]
	} else {
		set prefix ""
	}

	if {[llength $newstacktrace]} {
		return "${prefix}Error: $msg\n[stackdump $newstacktrace]"
	} else {
		return "${prefix}Error: $msg"
	}
}

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

# returns the number of cpus/cores if possible, or 1 if unknown
proc get-num-cpus {} {
	set numcpus 1
	catch {
		if {[iswin]} {
			# Actually, we always return 1 on Windows since without os.fork
			# we can't support concurrent jobs
			return 1

			# https://msdn.microsoft.com/en-us/library/aa394531(v=vs.85).aspx
			#set numcpus [lindex [exec wmic cpu get NumberOfCores] end]
		} else {
			# http://pubs.opengroup.org/onlinepubs/009604499/utilities/getconf.html
			set numcpus [exec getconf _NPROCESSORS_ONLN]
		}
	}
	return $numcpus
}

proc init-compat {} {
	# Do we have the signal command?
	if {![exists -command signal]} {
		proc signal {args} {
			# Return "no signal" for [signal check]
			return ""
		}
	}

	# How to eval a script and provide source info?
	# Older versions of Jim Tcl didn't support this
	if {[catch {info source {} t.tcl 1}] == 0} {
		# Have [info source]
		proc info-source {script filename line} {
			tailcall info source $script $filename $line
		}
	} else {
		proc info-source {script filename args} {
			return $script
		}
	}

	# Check SIGINT and SIGTERM with check-signal
	# SIGPIPE is caught in main
	# Only changes signals that exist and are set to default
	foreach {sig disp} {SIGINT ignore SIGTERM ignore SIGPIPE handle} {
		if {$sig in [signal default]} {
			signal $disp $sig
		}
	}
}
