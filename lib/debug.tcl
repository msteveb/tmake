##################################################################
#
# User and system warnings and errors
#
# Usage errors such as wrong command line options

# @user-error msg
#
# Indicate incorrect usage to the user, including if required components
# or features are not found.
# autosetup exits with a non-zero return code.
#
proc user-error {msg} {
	puts stderr "Error: $msg"
	puts stderr "Try: 'tmake --help' for options"
	exit 1
}

# @user-notice msg
#
# Output the given message to stderr.
#
proc user-notice {msg} {
	puts stderr $msg
}

# Incorrect usage in the build.spec file. Identify the location.
proc dev-error {msg} {
	puts stderr [error-location $msg]
	exit 1
}

proc vputs {msg} {
	if {$::tmake(verbose)} {
		puts $msg
	}
}

proc dputs {msg} {
	if {$::tmake(debug)} {
		puts [dbg-msg-indent]$msg
	}
}

proc dbg-msg-indent {} {
	string repeat "  " [llength $::tmake(current)]
}

proc showrules {rules} {
	set lines [split $rules \n]
	set first [lindex $lines 0]
	if {$first eq ""} {
		set lines [lrange $lines 1 end]
		set first [lindex $lines 0]
	}
	regexp {^(\s*)} $first -> space
	set trim [string length $space]
	set prefix \t
	foreach j $lines {
		set r [string trimright [string range $j $trim end]]
		if {$r ne ""} {
			puts $prefix$r
		}
	}
}

proc dumptarget {target} {
	if {[is-target? $target]} {
		set t [get-target $target]
		set flags {}
		set lines {}
		foreach n [lsort [dict keys $t]] {
			set v [dict get $t $n]
			switch -- $n {
				rules - depends - inputs - building - msg - target {}
				source {
					if {$v ne "unknown"} {
						puts @[join $v {, }]
					}
				}
				phony {
					if {$v} {
						lappend flags $n
					}
				}
				result {
					if {$v < 0} {
						lappend flags failed
					} elseif {$v > 0} {
						lappend flags built
					}
				}
				default {
					if {$v ne ""} {
						lappend lines "$n='$v'"
					}
				}
			}
		}
		if {[llength $flags]} {
			append target " \[$flags\]"
		}
		puts "$target: $t(depends)"
		if {[llength $lines]} {
			puts [join $lines \n]
		}
		showrules $t(rules)
	} else {
		puts "No rule to make $target"
	}
}

proc dumptargets {} {
	foreach i [lsort [dict keys $::tmake(targets)]] {
		puts "-------------------------------------------"
		dumptarget $i
		puts ""
	}
}

