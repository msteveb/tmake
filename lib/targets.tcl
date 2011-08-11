# ==================================================================
# Target Handling
# ==================================================================

proc is-target? {target} {
	dict exists $::tmake(targets) $target
}

proc get-target {target} {
	dict get $::tmake(targets) $target
}

proc set-target {target value} {
	dict set ::tmake(targets) $target $value
}

proc show-reason {targets} {
	foreach t $targets {
		set p [get-target $t]
		puts "[join $p(source) {, }] $t"
	}
}

proc show-this-rule {} {
	#dputs [info level -1]
}

proc get-clean {type} {
	dict get $::tmake(clean) $type
}

proc add-clean {type args} {
	set list [get-clean $type]
	lappend list {*}$args
	dict set ::tmake(clean) $type $list
}

proc install-file {dest src {bin 0}} {
	dict set ::tmake(installdirs) [file dirname $dest] 1
	if {[dict exists $::tmake(install) $dest]} {
		puts "Warning: Duplicate install rule for $dest"
	}
	dict set ::tmake(install) $dest $src
	dict set ::tmake(installbin) $dest $bin
	add-clean uninstall $dest
}

proc get-installdirs {} {
	prefix $::DESTDIR [lsort [dict keys $::tmake(installdirs)]]
}

proc find-rule-source {} {
	foreach i [range [info level]] {
		lassign [info frame $i] proc file line
		if {[string match *.spec $file]} {
			return $file:$line
		}
	}
	return unknown
}

proc target {target args} {
	set info(source) [find-rule-source]
	set info(result) 0
	set info(building) 0
	set info(target) $target
	set info(phony) 0
	set info(vars) {}
	set -inputs {}
	set -depends {}
	set -clean {}
	set -rules {}
	set -onfail {}
	set -msg {}
	set -vars {}

	foreach a $args {
		if {$a eq "-phony"} {
			incr info(phony)
			continue
		}
		if {[string match -* $a]} {
			if {![info exists $a]} {
				error "Unknown option to target: $a"
			}
			set current $a
		} else {
			lappend $current $a
		}
	}

	# Capture any specified local variables
	foreach v ${-vars} {
		dict set info(vars) $v [uplevel 1 set $v]
	}
	set info(inputs) [join ${-inputs}]
	set info(depends) [join ${-depends}]
	set info(clean) ${-clean}
	set info(onfail) ${-onfail}
	set info(rules) [lindex ${-rules} 0]
	set info(msg) [lindex ${-msg} 0]
	if {$info(rules) eq "" && [llength $info(inputs)]} {
		error "Inputs but no rules for $target at $info(source)"
	}
	if {$info(rules) eq "" && $info(msg) ne ""} {
		error "Message but no rules for $target at $info(source)"
	}

	if {[is-target? $target]} {
		set orig [get-target $target]
		if {$info(rules) ne "" && $orig(rules) ne ""} {
			error "Duplicate rules for $target at $info(source) and $orig(source)"
		}
		lappend info(depends) {*}$orig(depends)
		lappend info(inputs) {*}$orig(inputs)
		lappend info(clean) {*}$orig(clean)
		if {$info(source) eq "unknown"} {
			set info(source) $orig(source)
		} elseif {$orig(source) ne "unknown"} {
			lappend info(source) {*}$orig(source)
		}
		# Need to append to any vars which exist
		set info(vars) [merge-vars $orig(vars) $info(vars)]
		append-with-space info(onfail) $orig(onfail) \n
		if {$info(rules) eq ""} {
			set info(rules) $orig(rules)
			# Inputs go with the rules
			set info(inputs) $orig(inputs)
			set info(msg) $orig(inputs)
		}
		incr info(phony) $orig(phony)
	}
	set info(depends) [concat $info(depends) $info(inputs)]

	set-target $target $info
}

proc needbuild? {target source} {
	set result [get-target-result $target]
	if {$result} {
		return $result
	}
	if {[file exists $target]} {
		if {[file exists $source]} {
			if {[file mtime $target] >= [file mtime $source]} {
				dputs "$target is newer than $source, so not forcing rebuild"
				return 0
			}
		}
		dputs "$target is older than $source, so forcing rebuild"
		return 1
	} else {
		dputs "$target does not exist, so forcing build"
		return 1
	}
}

# Sets target-local variables. e.g. $inputs, $depends and $target
proc set-target-vars {info} {
	foreach {n v} $info(vars) {
		set ::$n $v
	}
	foreach n {target depends inputs} {
		set ::$n $info($n)
	}
}
proc clear-target-vars {info} {
	foreach n [dict keys $info(vars)] {
		set ::$n ""
	}
}

proc get-target-result {target} {
	if {![is-target? $target]} {
		return -1
	}
	dict get $::tmake(targets) $target result
}

proc set-target-result {target result} {
	if {[get-target-result $target] == 0} {
		dict set ::tmake(targets) $target result $result
	}
}

proc note {args} {
	if {$::tmake(verbose) == 0} {
		puts "[join $args]"
	}
}

proc run {args} {
	vputs [string trim [join $args]]
	try {
		exec {*}[join $args]
	} on error msg {
		puts stderr \n\t[join $args]\n
		puts stderr $msg\n
		return -code break
	}
}

proc build {target} {
	global tmake
	set current $tmake(current)
	lappend current $target
	if {![is-target? $target]} {
		if {[file exists $target]} {
			dputs "$target is not a target, but exists"
			return 0
		}
		dputs "$target is not a target and does not exist"
		return -1
	}
	set t [get-target $target]
	if {$t(result) < 0} {
		#dputs "$target has previously failed to build"
		return -1
	} elseif {$t(result) > 0} {
		#dputs "$target has previously been built"
		return 1
	}
	if {$t(building)} {
		puts stderr "Recursive definition for [join [lreverse $current] { <= }] @[join $t(source) {, }]"
		exit 1
	}
	dict set tmake(targets) $target building 1

	if {$t(phony)} {
		dputs "$target is phony, so rebuilding"
		set result 1
	} elseif {![file exists $target]} {
		dputs "$target doesn't exist, so rebuilding"
		set result 1
	} else {
		dputs "$target exists, so checking dependencies"
		set result 0
	}

	set oldcurrent $tmake(current)
	set tmake(current) $current

	# First make sure dependencies are up to date
	foreach i $t(depends) {
		#puts "Building $i"
		#dumptarget $i
		set rc [build $i]
		if {$rc < 0} {
			if {[get-target-result $target] >= 0} {
				puts stderr "Don't know how to build $i: [join [lreverse $current] { <= }] @[join $t(source) {, }]"
			}
			#dumptarget $target
			#show-reason $current
			set result -1
			if {$tmake(quickstop)} {
				break
			}
		} elseif {$result == 0} {
			if {$rc > 0} {
				dputs "Rebuilding $target because $i was built"
				set result 1
			} elseif {[needbuild? $target $i]} {
				set result 1
			}
		}
	}
	if {$result > 0 && $t(rules) ne ""} {
		#puts "Running rules for $target"
		dputs "Building [join [lreverse $current] { <= }] with rule @[join $t(source) {, }]"
		try {
			set-target-vars $t
			uplevel #0 $t(msg)
			if {$tmake(norun)} {
				showrules [uplevel #0 [list subst $t(rules)]]
				#parray t
			} else {
				uplevel #0 $t(rules)
				incr tmake(numtargets)
			}
		} on {error break} {msg opts} {
			file delete $target {*}$t(clean)
			try {
				uplevel #0 $t(onfail)
				if {[info returncode $opts(-code)] eq "error"} {
					puts stderr [errorInfo $msg]
				}
			} on error {fmsg fopts} {
				puts stderr [errorInfo $fmsg]
			}
			set result -1
		} finally {
			clear-target-vars $t
		}
	}

	# For each target, mark it as made (> 0) or unmakeable(< 0)
	if {$result != 0} {
		#puts "Marking target result=$result for $current"
		foreach t $current {
			set-target-result $t $result
		}
	}
	set tmake(current) $oldcurrent
	dict set tmake(targets) $target building 0
	return $result
}

proc find {filename} {
	return $filename
}
