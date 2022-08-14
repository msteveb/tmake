# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which can install tmake

proc tmake_install {dir} {
	if {$dir eq ""} {
		user-error "Usage: tmake --install=<dir>"
	}
	if {[catch {
		file mkdir $dir

		cd $dir

		set f [open tmake w]

		if {[file exists autosetup-find-tclsh]} {
			puts $f "#!/bin/sh"
			puts $f "# \\"
			puts $f {dir=`dirname "$0"`; exec "`$dir/autosetup-find-tclsh tmake-test-jimsh`" "$0" "$@"}
			file copy -force $::tmake(dir)/tmake-test-jimsh tmake-test-jimsh
			exec chmod +x tmake-test-jimsh
		}

		# Write the main script, but only up until "CUT HERE"
		set in [open $::tmake(dir)/tmake]
		while {[gets $in buf] >= 0} {
			if {$buf ne "##-- CUT HERE --##"} {
				puts $f $buf
				continue
			}

			# Insert the static modules here
			puts $f "set tmake(installed) 1"
			set modules {}
			foreach file [lsort [glob -nocomplain $::tmake(dir)/lib/*.tcl]] {
				lappend modules [file rootname [file tail $file]]
				puts $f "# ----- module [file tail $file] -----"
				puts $f [readfile $file]
			}
			foreach m $modules {
				puts $f "if {\[exists -proc init-$m\]} {init-$m}"
			}
			# Embed the default rulebase
			puts $f "set tmake(defaultrulebase) {[readfile $::tmake(dir)/rulebase.default]}"
		}
		close $in
		close $f
		exec chmod +x tmake
	} error]} {
		user-error "Failed to install tmake: $error"
	}
	exit 0
}
