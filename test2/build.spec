# Only if configured
ifconfig CONFIGURED

IncludePaths .

ifconfig JIM_SHAREDLIB {
	# Get the version from jim.h into version.conf
	# It is of the form: #define JIM_VERSION 71
	Generate version.conf {} jim.h {
		regexp {define JIM_VERSION ([0-9]+)} [readfile $inputs] -> version
		writefile $target "define JIM_VERSION [set version]\n"
	}
	# Load it
	Load version.conf
	ifconfig JIM_VERSION {
		# And use it when creating the shared lib
		alias Lib SharedLib --version=[format %.2f [expr {$JIM_VERSION / 100.0}]]
	}
}

UseSystemLibs $LIBS

set SRCS {}
define? DESTDIR _install

CFlags -I.

ifconfig USE_LINENOISE {
	define-append SRCS linenoise.c
}

Install $prefix/include jim.h jim-config.h jim-subcmd.h jim-win32compat.h jim-eventloop.h jim-nvp.h jim-signal.h

# C extensions can either be static or dynamic
foreach pkg $JIM_STATIC_C_EXTS {
	define-append SRCS jim-$pkg.c
}
foreach pkg $JIM_MOD_EXTENSIONS {
	SharedObject --install=$prefix/lib/jim $pkg.so jim-$pkg.c
}
foreach pkg $JIM_STATIC_TCL_EXTS {
	set src _jim$pkg.c
	Generate $src make-c-ext.tcl $pkg.tcl {
		run $tclsh $script $inputs >$target
	}
	define-append SRCS $src
}
ifconfig HAVE_WINDOWS {
	define-append SRCS jim-win32compat.c
}

Install $prefix/lib/jim [suffix .tcl $JIM_TCL_EXTENSIONS]

Generate _initjimsh.c make-c-ext.tcl initjimsh.tcl {
	run $tclsh $script $inputs >$target
}

Generate _loadstatic.c make-load-static-exts.tcl {} {
	run $tclsh $script $JIM_STATIC_TCL_EXTS $JIM_STATIC_C_EXTS >$target
}

ifconfig JIM_UTF8 {
	Generate _unicode_mapping.c parse-unidata.tcl UnicodeData.txt {
		run $tclsh $script $inputs >$target
	}
}

Lib --publish jim jim.c jim-subcmd.c jim-interactive.c jim-format.c utf8.c jimregexp.c _loadstatic.c _initjimsh.c $SRCS

Executable --install=$exec_prefix/bin jimsh jimsh.c

Test --interp=jimsh regtest.tcl

Generate Tcl.html make-index jim_tcl.txt {
	run $tclsh $script $inputs | asciidoc -o $target -d manpage -
}
Install $prefix/docs Tcl.html README.jim=README
Phony docs Tcl.html

DistClean jim-config.h jimautoconf.h config.log settings.conf
