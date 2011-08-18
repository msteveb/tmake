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
set LOCAL_LIBS ""
set DESTDIR ""
set OBJCFLAGS ""

# XXX Should be $TOP/publish
set PUBLISH publish

# XXX: Either reuse cc-shared.tcl or expect these to be set
#      in settings.conf
#
define SH_CFLAGS -dynamic
define SH_LDFLAGS "-dynamiclib"
define SHOBJ_CFLAGS "-dynamic -fno-common"
define SHOBJ_LDFLAGS "-bundle -undefined dynamic_lookup"

set PROJLIBS ""
set SYSLIBS ""

set OBJRULES(.c) {run $CCACHE $CC $CFLAGS $OBJCFLAGS -c $inputs -o $target}
set OBJMSG(.c) {note Cc $target}
set OBJVARS(.c) {CFLAGS}
set OBJRULES(.cpp) {run $CCACHE $CXX $CXXFLAGS $OBJCFLAGS -c $inputs -o $target}
set OBJVARS(.cpp) {CXXFLAGS}
set OBJMSG(.cpp) {note C++ $target}
set HDRPATTERN {^[\t ]*#[\t ]*include[\t ]*[<\"]([^\">]*)[\">]}
set HDRSCAN(.c) {header-scan-regexp-recursive $HDRPATTERN}
set HDRSCAN(.cpp) {header-scan-regexp-recursive $HDRPATTERN}

set EXERULE {run $CC $SH_LINKFLAGS $LDFLAGS -o $target $inputs $SYSLIBS}
set SHAREDOBJRULE {run $CC $SHOBJ_LDFLAGS -o $target $inputs $SYSLIBS}
set ARRULE {
	run $AR $ARFLAGS $target $inputs
	run $RANLIB $target
}

lappend tmake(subdirvars) CFLAGS CXXFLAGS LDFLAGS PROJLIBS SYSLIBS tmake(includepaths)

# ==================================================================
# PROLOG/EPILOG HOOKS
# ==================================================================
proc BuildSpecProlog {} {
	# Local phony targets build from the current directory down
	if {[local-prefix] ne ""} {
		foreach t {all clean distclean test} {
			Phony $t [make-local $t]
			Phony [make-local $t]
		}
		CleanTarget clean
		CleanTarget distclean
	}
}

proc BuildSpecEpilog {} {
}

# ==================================================================
# HIGH LEVEL RULES
# ==================================================================

proc Executable {args} {
	show-this-rule
	getopt {--test --publish --install: target args} args
	if {$publish} {
		# Revisit: --publish=newname?
		Publish bin $target
	}
	set target [make-local $target]
	Link $target {*}[Objects {*}[join $args]] $::LOCAL_LIBS {*}$::PROJLIBS
	if {[info exists install]} {
		Install --bin $install $target
	}
	if {$test} {
		Test $target
	} else {
		Phony [make-local all] $target
	}
}

# Link an executable from objects
proc Link {target args} {
	show-this-rule
	target $target -inputs {*}$args -do $::EXERULE -msg {note Link $target}
	Clean clean $target
}

proc Publish {dir args} {
	show-this-rule
	foreach t [make-local $args] {
		set dest [file join $dir [file tail $t]]
		HardLink [file join $::PUBLISH $dest] $t -vars dest $dest -msg {note Publish $dest}
	}
}

proc ArchiveLib {args} {
	show-this-rule
	getopt {--publish --install: libname args} args

	set target [make-local lib$libname.a]
	target $target -inputs {*}[Objects {*}[join $args]] -do $::ARRULE -msg {note Ar $target}
	Phony [make-local all] $target
	Clean clean $target
	define-append LOCAL_LIBS $target

	if {[info exists install]} {
		Install $install $target
	}
	if {$publish} {
		Publish lib lib$libname.a
	}
}

alias Lib ArchiveLib

proc SharedObject {args} {
	show-this-rule
	# REVISIT: Should allow getopt to also checked fixed args too
	#          so we can produce a nice error message
	# Like: getopt SharedObject {install: test} target srcs...
	#
	getopt {--install: sharedobj args} args

	set sharedobj [make-local $sharedobj]

	# XXX: Should build objects with -fpic, etc.
	# Use -vars/ObjectCFlags to do this
	SharedObjectLink $sharedobj {*}[Objects {*}[join $args]]
	Phony [make-local all] $sharedobj
	if {[info exists install]} {
		Install --bin $install $sharedobj
	}
}

# Link an executable from objects
proc SharedObjectLink {target args} {
	show-this-rule
	# Note that we only link against local shared libs, not archive libs
	target $target -inputs {*}$args -do $::SHAREDOBJRULE -msg {note SharedObject $target}
	Clean clean $target
}

# Create an object file from each source file
# Uses $OBJSRULES(.ext) to determine the build rule
# Returns a list of objects
# Accepts object files (.o) in addition to source files
# and simply returns them
proc Objects {args} {
	show-this-rule
	set objs {}
	foreach src $args {
		lappend objs [Object [change-ext .o $src] $src]
	}
	return $objs
}

proc Object {obj src} {
	show-this-rule
	set ext [file ext $src]
	set obj [make-local $obj]
	set src [make-local $src]
	if {$ext ne ".o"} {
		set extra {}
		if {![info exists ::OBJRULES($ext)]} {
			dev-error "Don't know how to build Object from $src"
		}
		if {[info exists ::OBJMSG($ext)]} {
			lappend extra -msg $::OBJMSG($ext)
		}
		if {[info exists ::OBJVARS($ext)]} {
			lappend extra -vars
			foreach v $::OBJVARS($ext) {
				lappend extra $v [set ::$v]
			}
		}
		if {[info exists ::HDRSCAN($ext)]} {
			lappend extra -dyndep $::HDRSCAN($ext)
		}
		target $obj -inputs $src -do $::OBJRULES($ext) {*}$extra
		Clean clean $obj
	}
	return $obj
}

# Set object-specific CFLAGS
proc ObjectCFlags {srcs args} {
	show-this-rule
	foreach src $srcs {
		set obj [change-ext .o $src]
		target $obj -vars OBJCFLAGS [join $args]
	}
}

proc CFlags {args} {
	show-this-rule
	define-append CFLAGS {*}$args
}

proc C++Flags {args} {
	define-append CXXFLAGS {*}$args
}

proc LinkFlags {args} {
	define-append LDFLAGS {*}$args
}

proc UseLibs {args} {
	foreach lib $args {
		# REVISIT: If we are to support linking against project shared libs, PROJLIBS
		#          needs to be just a list of libs which will then be resolved to actual
		#          targets (archive or shared) at deferred resolution time
		define-append PROJLIBS [file join $::PUBLISH lib lib$lib.a]
	}
}

proc IncludePaths {args} {
	show-this-rule
	set paths [make-local {*}$args]
	lappend ::tmake(includepaths) $paths
	CFlags [prefix -I $paths]
}

proc Load {filename} {
	if {![file exists $filename]} {
		puts "Warning: $filename does not yet exist"
	} else {
		uplevel #0 [list source $filename]
	}
}

proc UseSystemLibs {args} {
	define-append SYSLIBS {*}$args
}

proc PublishIncludes {args} {
	foreach a [join $args] {
		Publish include $a
	}
}

proc Test {args} {
	getopt {--runwith: command args} args
	set testid test:[incr ::testid]
	set depends {}
	# XXX: If cross compiling, the existence of $runwith
	#      and $command as targets is no guarantee that they
	#      can run.
	set maybe-depends $command
	if {[info exists runwith]} {
		set testcommand "$runwith $command [join $args]"
		lappend maybe-depends $runwith
	} else {
		set testcommand "./$command [join $args]"
	}
	# Note: We don't yet know if $runwith and/or $command are targets, so defer until all rules are read.
	# 
	Phony $testid -maybe-depends {*}${maybe-depends} -vars testcommand $testcommand command $command -msg {note "Test $command"} -do {
		incr ::tmake(testruncount)
		run {*}$testcommand
		incr ::tmake(testpasscount)
	}
	Phony [make-local test] $testid

	return $testid
}

proc HardLink {args} {
	show-this-rule

	getopt {--fallback dest source args} args

	# XXX: If the platform doesn't support hard links
	# and --fallback is set, fall back to soft links
	# and then to file copy
	target $dest -inputs $source -do {
		file mkdir [file dirname $target]
		exec ln $inputs $target
	} {*}$args
	Clean clean $dest
}

# Helper for installing files
proc install-file {target source bin} {
	file mkdir [file dirname $target]
	vputs "Copy $source $target"
	file copy -force $source $target
	if {$bin} {
		vputs "chmod +x $target"
		exec chmod +x $target
	}
}

proc InstallFile {dest src {bin 0}} {
	show-this-rule

	set destfile $::DESTDIR$dest
	target $destfile -inputs $src -vars dest $dest bin $bin -msg {note "Install $dest"} -do {
		install-file $target $inputs $bin
	}
	Depends install $destfile

	# This file also needs to be uninstalled
	Clean uninstall $destfile

	#if {[dict exists $::tmake(install) $dest]} {
	#	user-notice "Warning: Duplicate install rule for $dest"
	#}
}

proc Install {args} {
	show-this-rule

	getopt {--bin --keepdir dest args} args

	set srcs {}
	foreach i $args {
		if {[string match {*[*?]*} $i]} {
			set flist [glob $i]
		} elseif {[string match *=* $i]} {
			lassign [split $i =] src target
			lappend srcs $src
			InstallFile [file join $dest $target] $src $bin
			continue
		} else {
			set flist $i
		}
		foreach j $flist {
			lappend srcs $j
			if {$keepdir} {
				InstallFile [file join $dest $j] $j $bin
			} else {
				InstallFile [file join $dest [file tail $j]] $j $bin
			}
		}
	}
}

# This creates the clean target of the given type, e.g. clean, distclean
#
proc CleanTarget {type} {
	Phony [make-local $type] -nofail -vars cleanfiles {} -do {
		note "Clean $target"
		if {[llength $cleanfiles]} {
			vputs "rm $cleanfiles"
			file delete {*}$cleanfiles
		}
	}
}

# This adds files to be cleaned for the given type
#
proc Clean {type args} {
	Phony [make-local $type] -vars cleanfiles [join $args]
}

proc Generate {target script inputs rules} {
	# XXX: Would be nice if script and inputs were optional
	target $target -inputs {*}$inputs -depends $script -vars script $script -do $rules -msg {note Generate $target}
	Clean clean $target
}

proc Depends {target args} {
	target $target -depends {*}$args
}

proc Phony {target args} {
	show-this-rule
	Depends $target -phony -depends {*}$args
}

# ==================================================================
# Built-in targets
# ==================================================================

CleanTarget clean
CleanTarget distclean
CleanTarget uninstall

Depends distclean clean

Phony all
Phony install all
Phony test -do {
	# XXX: Need this to be a "run-anyway" command so that even if some tests fail it will still run
	# Actually, tests should not be targets. 
	puts [format "Test Summary: %d of %d passed" $tmake(testpasscount) $tmake(testruncount)]
}

# XXX: Should be a better way to do this
IncludePaths $PUBLISH/include
