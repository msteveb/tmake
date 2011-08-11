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

proc dputs {msg} {
	if {$::tmake(debug)} {
		puts [dbg-msg-indent]$msg
	}
}

proc dbg-msg-indent {} {
	string repeat "  " [llength $::tmake(current)]
}

proc showrules {rules} {
	foreach j [split $rules \n] {
		set r [string trim $j]
		if {$r ne ""} {
			puts "\t$r"
		}
	}
}

proc dumptarget {target} {
	if {[is-target? $target]} {
		set t [get-target $target]
		puts "$target: $t(depends)"
		showrules $t(rules)
		#set V $t(vars)
		#parray V
		parray t
	} else {
		puts "No rule to make $target"
	}
}

proc dumptargets {} {
	parray ::tmake
	foreach i [lsort [dict keys $::tmake(targets)]] {
		puts "dumptarget $i"
		dumptarget $i
		puts ""
	}
}

