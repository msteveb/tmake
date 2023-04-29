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

if {"split" in [file -commands]} {
    alias file-split file split
} else {
    proc file-split {path} {
        if {[string match /* $path]} {
            set parts [split $path /]
            list / {*}$parts
        } else {
            split $path /
        }
    }
}
if {"join" in [file -commands]} {
    alias file-join-raw file join
} else {
    proc file-join-raw {args} {
        join $args /
    }
}

# @file-join dir path
#
# Like 'file join' except will omit "." in either 'dir' or 'path'
# and will reduce ..
# e.g.
#
## file-join . abc => abc
## file-join abc/def . => abc/def
## file-join abc/def ghi => abc/def/ghi
## file-join abc/def ../ghi => abc/ghi
proc file-join {dir path} {
	set result {}
	foreach part [list {*}[file-split $dir] {*}[file-split $path]] {
		if {$part eq "."} {
			continue
		}
		if {$part eq ".."} {
			if {[lindex $result end] ni {".." ""}} {
				set result [lrange $result 0 end-1]
				continue
			}
		}
		if {[string match /* $part]} {
			set result {}
		}
		lappend result $part
	}
	if {[llength $result] == 0} {
		return "."
	}
	file-join-raw {*}$result
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
} elseif {![iswin]} {
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
# Return modification time of the file, using the high-res timestamp if possble.
#
# @file-lmtime linkname
#
# Return modification time of the symlink, using the high-res timestamp if possble.
#
if {"mtimeus" in [file -commands]} {
	alias file-mtime file mtimeus
	proc show-mtime {mtime} {
		set ms_str [format %03d $($mtime / 1000 % 1000)]
		set secs $($mtime / 1000000)
		return [clock format $secs -format "%H:%M:%S.$ms_str %d-%b-%Y"]
	}
	proc file-lmtime {filename} {
		dict get [file-lstat $filename] mtimeus
	}
} else {
	alias file-mtime file mtime
	proc show-mtime {mtime} {
		return [clock format $mtime -format "%H:%M:%S %d-%b-%Y"]
	}
	proc file-lmtime {filename} {
		dict get [file-lstat $filename] mtime
	}
}

# @file-lstat filename ?var?
#
# Implements 'file lstat', or 'file stat' if lstat isn't supported.
#
if {"lstat" in [file -commands]} {
	alias file-lstat file lstat
} else {
	alias file-lstat file stat
}

# Like file type but returns "none" if the file doesn't exist
# rather than throwing an error
proc file-type {file} {
	set type none
	catch {
		set type [file type $file]
	}
	return $type
}

if {"getwithdefault" in [dict -commands]} {
	alias dict-getdef dict getdef
} else {
	proc dict-getdef {dict keys default} {
		if {[dict exists $dict {*}$keys]} {
			dict get $dict {*}$keys
		} else {
			return $default
		}
	}
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
# should be generated in user code (e.g. *.spec).
# By default, we only want to show the error location in user code.
# We use [stacktrace] to achieve this.
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
proc warning-location {msg} {
	set loc [lindex [find-source-location] 0]
	if {$loc ne "unknown"} {
		return "$loc: $msg"
	}
	puts "warning-location: no location found"
	return $msg
}

# Traverse stack frames and find each location in *.spec and *.default files,
# starting with the top-most level.
# 
# Returns a list: {file:line ...} or "unknown" if none found.
#
proc find-source-location {} {
	set specresult {}
	set defaultresult {}
	foreach {p f l} [stacktrace] {
		if {[string match *.spec $f]} {
			lappend specresult [relative-path $f]:$l
		} elseif {[string match *.default $f]} {
			# No need to include the location in rulebase.default if there are other locations
			# And only need one location from rulebase.default
			if {[llength $defaultresult] == 0} {
				# rulebase.default is outside the project so use the path directly
				lappend defaultresult $f:$l
			}
		}
	}
	if {[llength $specresult]} {
		return $specresult
	}
	if {[llength $defaultresult]} {
		return $defaultresult
	}

	return unknown
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

# Returns 1 if the current user is root
# On platforms with no concept of root, always returns 0
proc is-uid-root {} {
	if {[exists -command os.getids]} {
		if {[dict get [os.getids] uid] == 0} {
			return 1
		}
	}
	return 0
}

# Returns 1 if md5sum hashing is available
proc init-md5sum {} {
	set nullmd5 "d41d8cd98f00b204e9800998ecf8427e"
	catch -noreturn {
		package require md5
		if {[md5 -hex ""] eq $nullmd5} {
			proc md5sum {filename} {
				if {![file exists $filename]} {
					build-error "md5sum $filename does not exist"
				}
				md5 -hex [readfile $filename]
			}
			dputs {h m} "Using md5 module for hashing"
			return 1
		}
	}
	foreach cmd {md5sum md5} {
		if {[catch [list exec $cmd /dev/null] result] == 0} {
			lassign $result sum
			if {$sum eq $nullmd5} {
				# OK. Create the md5sum proc
				proc md5sum {filename} cmd {
					if {![file exists $filename]} {
						build-error "md5sum $filename does not exist"
					}
					lindex [exec $cmd $filename] 0
				}
				dputs {h m} "Using external $cmd for hashing"
				return 1
			}
		}
	}
	return 0
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
