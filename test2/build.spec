# vim:set syntax=tcl:

Load --required settings.conf
Depends settings.conf auto.def -do {
	note "Configure"
	run $AUTOREMAKE >config.out
}

if {$JIM_SHAREDLIB} {
	dev-error "Sorry, --shared not yet implemented in tmake"
}

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

ArchiveLib jim jim.c jim-subcmd.c jim-interactive.c jim-format.c utf8.c jimregexp.c _loadstatic.c _initjimsh.c $SRCS

Executable --install=$exec_prefix jimsh jimsh.c

Test --runwith=jimsh regtest.tcl

Generate Tcl.html make-index jim_tcl.txt {
	run $tclsh $script $inputs | asciidoc -o $target -d manpage -
}
Install $prefix/docs Tcl.html

Phony docs Tcl.html

Clean distclean jim-config.h jimautoconf.h config.log settings.conf
