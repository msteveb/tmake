# These are the built-in rules
#
# They can be replaced if necessary

# ==================================================================
# Default variable settings and rules
# ==================================================================

set CCACHE ""
set CC cc
set CC_FOR_BUILD cc
set CXX c++
set AR ar
set RANLIB ranlib
set ARFLAGS cr
set CFLAGS ""
set CXXFLAGS ""
set SH_LINKFLAGS ""
set LDFLAGS ""
set SYSLIBS ""
set LOCAL_LIBS ""
set DESTDIR ""
set OBJCFLAGS ""

# XXX: Either reuse cc-shared.tcl or expect these to be set
#      in settings.conf
#
define SH_CFLAGS -dynamic
define SH_LDFLAGS "-dynamiclib"
define SHOBJ_CFLAGS "-dynamic -fno-common"
define SHOBJ_LDFLAGS "-bundle -undefined dynamic_lookup"

set OBJRULES(.c) {run $CCACHE $CC $CFLAGS $OBJCFLAGS -c $inputs -o $target}
set OBJMSG(.c) {note Cc $target}
set OBJRULES(.cpp) {run $CCACHE $CXX $CXXFLAGS $OBJCFLAGS -c $inputs -o $target}
set OBJMSG(.cpp) {note C++ $target}
set EXERULE {run $CC $SH_LINKFLAGS $LDFLAGS -o $target $inputs $SYSLIBS}
set SHAREDOBJRULE {run $CC $SHOBJ_LDFLAGS -o $target $inputs $SYSLIBS}
set ARRULE {
	run $AR $ARFLAGS $target $inputs
	run $RANLIB $target
}

# ==================================================================
# Built-in targets
# ==================================================================

target clean -rules {
	note "Clean clean"
	set files [get-clean clean]
	if {[llength $files]} {
		vputs "rm $files"
		file delete {*}$files
	}
}

target distclean -rules {
	note "Clean distclean"
	set files [concat [get-clean clean] [get-clean distclean]]
	if {[llength $files]} {
		vputs "rm $files"
		file delete {*}$files
	}
}

target install -rules {
	# First create all the directories
	file mkdir {*}[get-installdirs]

	set prevdir ""

	foreach dest [lsort [dict keys $::tmake(install)]] {
		set src [dict get $::tmake(install) $dest]
		set bin [dict exists $::tmake(installbin) $dest]
		set dest $::DESTDIR$dest
		if {![file exists $dest] || [file mtime $dest] < [file mtime $src]} {
			set dir [file dirname $dest]
			if {$dir ne $prevdir} {
				note "Install $dir"
				set prevdir $dir
			}
			vputs "Copy $src $dest"
			file copy -force $src $dest
			if {$bin} {
				vputs "chmod +x $dest"
				exec chmod +x $dest
			}
		}
	}
}

target uninstall -rules {
	note "Clean uninstall"
	set files [prefix $::DESTDIR [get-clean uninstall]]
	if {[llength $files]} {
		vputs "rm $files"
		file delete {*}$files
	}
	foreach i [get-installdirs] {
		file delete -force $i
	}
}

# ==================================================================
# HIGH LEVEL RULES
# ==================================================================

proc Executable {target {args srcs}} {
	show-this-rule
	set test 0
	while {[string match --* $target]} {
		if {[regexp {^--install=(.*)} $target -> installdir} {
			# Will install to $installdir
		} elseif {$target eq "--test"} {
			incr test
		} else {
			error "Uknown option $target"
		}
		set srcs [lassign $srcs target]
	}
	Link $target {*}[Objects {*}[join $srcs]]
	Depends all $target
	if {[exists installdir]} {
		Install $installdir $target
	}
	if {$test} {
		# XXX: RunTest $target
	}
}

# Link an executable from objects
proc Link {target {args objs}} {
	show-this-rule
	target $target -inputs {*}$objs $::LOCAL_LIBS -rules $::EXERULE -msg {note Link $target}
	Clean clean $target
}

proc ArchiveLib {base {args srcs}} {
	show-this-rule
	set libname lib$base.a
	target $libname -inputs {*}[Objects {*}[join $srcs]] -rules $::ARRULE -msg {note Ar $target}
	target all -depends $libname
	Clean clean $libname
	define-append LOCAL_LIBS $libname
}

alias Lib ArchiveLib

proc SharedObject {target {args srcs}} {
	show-this-rule
	# XXX: Should build objects with -fpic, etc.
	SharedObjectLink $target {*}[Objects {*}[join $srcs]]
	Depends all $target
}

# Link an executable from objects
proc SharedObjectLink {target {args objs}} {
	show-this-rule
	# Note that we only link against local shared libs, not archive libs
	target $target -inputs {*}$objs -rules $::SHAREDOBJRULE -msg {note SharedObject $target}
	Clean clean $target
}

proc Phony {target {args deps}} {
	Depends all {*}$deps
}

# Create an object file from each source file
# Uses $OBJSRULES(.ext) to determine the build rule
# Returns a list of objects
proc Objects {{args srcs}} {
	show-this-rule
	set objs {}
	foreach src $srcs {
		set obj [change-ext .o $src]
		lappend objs $obj
		if {![info exists ::OBJRULES([file ext $src])} {
			error "Don't know how to build object from $src"
		}
		target $obj -inputs $src -rules $::OBJRULES([file ext $src]) -msg $::OBJMSG([file ext $src])
		Clean clean $obj
	}
	return $objs
}

# Set object-specific CFLAGS
proc ObjectCFlags {srcs {args flags}} {
	show-this-rule
	foreach src $srcs {
		set obj [change-ext .o $src]
		set OBJCFLAGS [join $flags]
		target $obj -vars OBJCFLAGS
	}
}

proc CFlags {{args flags}} {
	define-append CFLAGS {*}$flags
}

proc C++Flags {{args flags}} {
	define-append CXXFLAGS {*}$flags
}

proc LinkFlags {{args flags}} {
	define-append LDFLAGS {*}$flags
}

proc Load {filename} {
	if {![file exists $filename]} {
		puts "Warning: $filename does not yet exist"
	} else {
		uplevel #0 [list source $filename]
	}
}

proc UseSystemLibs {{args libs}} {
	define-append SYSLIBS {*}$libs
}

proc PublishIncludes {{args includes}} {
	#target 
}

proc PublishArchiveLibs {{args libs}} {
	#target 
}

proc RunTest {{args cmd}} {
	#target 
}

proc Install {dest {args files}} {
	show-this-rule
	set bin 0
	set files [join $files]
	if {$dest eq "--bin"} {
		incr bin
		set files [lassign $files dest]
	}

	# pairs of src dest
	set srcs {}
	foreach i $files {
		if {[string match {*[*?]*} $i]} {
			foreach j [glob $i] {
				lappend srcs $j
				install-file [file join $dest [file tail $j]] $j $bin
			}
		} elseif {[string match *=* $i]} {
			lassign [split $i =] src target
			lappend srcs $src
			install-file [file join $dest $target] $src $bin
		} else {
			lappend srcs $i
			install-file [file join $dest [file tail $i]] $i $bin
		}
	}
	Depends install {*}$srcs
}

proc Clean {type {args files}} {
	add-clean $type {*}$files
}

proc Generate {target script inputs rules} {
	target $target -inputs {*}$inputs -depends $script -vars script -rules $rules -msg {note Generate $target}
	Clean clean $target
}

proc Depends {target {args depends}} {
	target $target -depends {*}$depends
}

proc Alias {target other} {
	target $target -depends $other
}

proc Action {target rules} {
	target $target -rules $rules
}

