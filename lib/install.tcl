# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which can install tmake

proc tmake_install {dir} {
	if {[catch {
		cd $dir

		set f [open tmake w]

		# First the main script, but only up until "CUT HERE"
		set in [open $::tmake(dir)/tmake]
		while {[gets $in buf] >= 0} {
			if {$buf ne "##-- CUT HERE --##"} {
				puts $f $buf
				continue
			}

			# Insert the static modules here
			puts $f "set tmake(installed) 1"
			foreach file [lsort [glob -nocomplain $::tmake(dir)/lib/*.tcl]] {
				puts $f "# ----- module [file tail $file] -----"
				puts $f [readfile $file]
			}
		}
		close $in
		close $f
		exec chmod 755 tmake
		writefile rulebase.default [readfile $::tmake(dir)/rulebase.default]
	} error]} {
		user-error "Failed to install tmake: $error"
	}
	exit 0
}