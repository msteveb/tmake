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
set HDRPATTERN {^[\t ]*#[\t ]*include[\t ]*[<\"]([^\">]*)[\">]}
set HDRSCAN(.c) {header-scan-regexp-recursive $HDRPATTERN}
set HDRSCAN(.cpp) {header-scan-regexp-recursive $HDRPATTERN}

set EXERULE {run $CC $SH_LINKFLAGS $LDFLAGS -o $target $inputs $SYSLIBS}
set SHAREDOBJRULE {run $CC $SHOBJ_LDFLAGS -o $target $inputs $SYSLIBS}
set ARRULE {
	run $AR $ARFLAGS $target $inputs
	run $RANLIB $target
}

# ==================================================================
# HIGH LEVEL RULES
# ==================================================================

proc Executable {args} {
	show-this-rule
	array set opts [getopt {test install:} args]
	set args [lassign $args target]
	Link $target {*}[Objects {*}[join $args]]
	Depends all $target
	if {[info exists opts(install)]} {
		Install --bin $opts(install) $target
	}
	if {$opts(test)} {
		# XXX: RunTest $target
	}
}

# Link an executable from objects
proc Link {target args} {
	show-this-rule
	target $target -inputs {*}$args $::LOCAL_LIBS -do $::EXERULE -msg {note Link $target}
	Clean clean $target
}

proc ArchiveLib {base args} {
	show-this-rule
	set libname lib$base.a
	target $libname -inputs {*}[Objects {*}[join $args]] -do $::ARRULE -msg {note Ar $target}
	Depends all $libname
	Clean clean $libname
	define-append LOCAL_LIBS $libname
}

alias Lib ArchiveLib

proc SharedObject {args} {
	show-this-rule
	# REVISIT: Should allow getopt to also checked fixed args too
	#          so we can produce a nice error message
	# Like: getopt SharedObject {install: test} target srcs...
	#
	array set opts [getopt {install:} args]
	set args [lassign $args target]
	# XXX: Should build objects with -fpic, etc.
	# Use -vars to do this
	SharedObjectLink $target {*}[Objects {*}[join $args]]
	Depends all $target
	if {[info exists opts(install)]} {
		Install --bin $opts(install) $target
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
proc Objects {args} {
	show-this-rule
	set objs {}
	foreach src $args {
		set obj [change-ext .o $src]
		set ext [file ext $src]
		lappend objs $obj
		set extra {}
		if {![info exists ::OBJRULES($ext)]} {
			dev-error "Don't know how to build Object from $src"
		}
		if {[info exists ::OBJMSG($ext)]} {
			lappend extra -msg $::OBJMSG($ext)} {
		}
		if {[info exists ::HDRSCAN($ext)]} {
			lappend extra -dyndep $::HDRSCAN($ext)} {
		}
		target $obj -inputs $src -do $::OBJRULES($ext) {*}$extra
		Clean clean $obj
	}
	return $objs
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
	define-append CFLAGS {*}$args
}

proc C++Flags {args} {
	define-append CXXFLAGS {*}$args
}

proc LinkFlags {args} {
	define-append LDFLAGS {*}$args
}

proc IncludePaths {args} {
	lappend ::tmake(includepaths) {*}$args
	CFlags [prefix -I $args]
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
	error "not yet implemented"
}

proc PublishArchiveLibs {args} {
	error "not yet implemented"
}

proc RunTest {{args cmd}} {
	error "not yet implemented"
}

proc Install {args} {
	show-this-rule

	array set opts [getopt {test bin} args]
	set files [lassign $args dest]

	# pairs of src dest
	set srcs {}
	foreach i $files {
		if {[string match {*[*?]*} $i]} {
			foreach j [glob $i] {
				lappend srcs $j
				add-install-file [file join $dest [file tail $j]] $j $opts(bin)
			}
		} elseif {[string match *=* $i]} {
			lassign [split $i =] src target
			lappend srcs $src
			add-install-file [file join $dest $target] $src $opts(bin)
		} else {
			lappend srcs $i
			add-install-file [file join $dest [file tail $i]] $i $opts(bin)
		}
	}
	Depends install {*}$srcs
}

proc Clean {type args} {
	add-clean $type {*}[join $args]
}

proc Generate {target script inputs rules} {
	target $target -inputs {*}$inputs -depends $script -vars script $script -do $rules -msg {note Generate $target}
	Clean clean $target
}

proc Depends {target args} {
	target $target -depends {*}$args
}

proc Phony {target args} {
	Depends $target -phony -depends {*}$args
}

# ==================================================================
# Built-in targets
# ==================================================================

Phony clean -do {
	note "Clean clean"
	set files [get-clean clean]
	if {[llength $files]} {
		vputs "rm $files"
		file delete {*}$files
	}
}

Phony distclean -do {
	note "Clean distclean"
	set files [concat [get-clean clean] [get-clean distclean]]
	if {[llength $files]} {
		vputs "rm $files"
		file delete {*}$files
	}
}

Phony install -do {
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

Phony uninstall -do {
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

Phony all
Phony test
