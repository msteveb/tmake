# Here is how it works.
#
# The 'filedef' declaration associates a name with a file+contents
# For example:
#
# filedef simpleprojspec project.spec {
#   CFlags -DTEST
#   IncludePaths .
# }
# 
# Helper functions exist to setup, step through and check scenarios
#
# runtest    - run a series of tests (init, tests, cleanup)
# makefiles  - create/update files
# rmfiles    - delete files
# msg        - output a progress message
# build      - run tmake
# checkbuilt - check that exactly the specified targets were built

set topdir [pwd]
set tmpdir $topdir/_build_
set filedefs {}
#set tmake_cmd [list jimsh $topdir/../tmake]
set tmake_cmd tmake

proc readfile {filename {default_value ""}} {
	set result $default_value
	catch {
		set f [open $filename]
		set result [read -nonewline $f]
		close $f
	}
	return $result
}

proc writefile {filename value} {
	file mkdir [file dirname $filename]
	set f [open $filename w]
	puts -nonewline $f $value
	close $f
}

proc filedef {name path contents} {
	set ::filedefs($name) [list $path $contents]
}

proc makefiles {args} {
	foreach name $args {
		if {![dict exists $::filedefs $name]} {
			error "No such file definition: $name"
		}
		lassign [dict get $::filedefs $name] path contents
		file mkdir [file dirname $path]
		writefile $path $contents
	}
}

proc rmfiles {args} {
	foreach name $args {
		if {![dict exists $::filedefs $name]} {
			error "No such file definition: $name"
		}
		lassign [dict get $::filedefs $name] path contents
		file delete $path
	}
}

# Reset to an empty workspace
proc resetbuild {} {
	cleanupbuild

	file mkdir $::tmpdir
	cd $::tmpdir
}

proc cleanupbuild {} {
	cd $::topdir
	exec rm -rf $::tmpdir
}

proc runtest {description script} {
	puts "================================"
	puts "Test: $description"
	puts "================================"
	resetbuild
	eval $script
	cleanupbuild
}

proc msg {msg} {
	puts "-------------------------"
	puts "*** $msg ***\n"
}

proc checkbuilt {args} {
	# Did we built only what we wanted to build?
	if {[lsort $args] ne $::builtfiles} {
		puts stderr "Built files did not match"
		puts stderr "Wanted: [lsort $args]"
		puts stderr "Got:    $::builtfiles"
		exit 1
	}
}

proc build {args} {
	# Now run tmake with the given targets
	exec {*}$::tmake_cmd --quiet {*}$args >build.out 2>@stderr

	# Ugly!
	array unset ::built

	set ::buildlog [readfile build.out]
	puts $::buildlog

	foreach line [split $::buildlog  \n] {
		set ::built([lindex $line end]) $line
	}
	set ::builtfiles [lsort [array names ::built]]
	# If using a filesystem with 1 second timestamp resolution, need to sleep
	# for that long!
	#sleep 1
}
