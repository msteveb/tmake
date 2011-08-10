Load settings.conf

set extrasrcs {}

CFlags -I.

ifconfig JIM_MATH_FUNCTIONS {
	UseSystemLibs -lm
}
ifconfig JIM_O2 {
	CFlags -O2 -fomit-frame-pointer 
}
ifconfig JIM_REGEX {
	CFlags -DJIM_REGEXP
}
ifconfig USE_LINENOISE {
	define-append extrasrcs linenoise.c
}

#PublishIncludes jimautoconf.h=jimautoconf.h.automf
#PublishIncludes jim.h jim-subcmd.h jim-win32compat.h
#Install /include jim.h jim-subcmd.h jim-win32compat.h

set JIM_MOD_EXTENSIONS {}
set JIM_REFERENCES 1
set JIM_STATIC_C_EXTS {aio array clock eventloop exec file load package posix readdir regexp signal syslog}
set JIM_STATIC_TCL_EXTS {glob stdlib tclcompat}

# C extensions can either be static or dynamic
foreach pkg $JIM_STATIC_C_EXTS {
	lappend extrasrcs jim-$pkg.c
}

foreach pkg $JIM_STATIC_TCL_EXTS {
	set src _jim$pkg.c 
	Generate $src make-c-ext.tcl $pkg.tcl {
		run $tclsh $script $inputs >$target
	}
	define-append extrasrcs $src
}

Generate _initjimsh.c make-c-ext.tcl initjimsh.tcl {
	run $tclsh $script $inputs >$target
}

Generate _loadstatic.c make-load-static-exts.tcl {} "run \$tclsh \$script $JIM_STATIC_TCL_EXTS $JIM_STATIC_C_EXTS >\$target"

ifconfig JIM_UTF8 {
	Generate _unicode_mapping.c parse-unidata.tcl UnicodeData.txt {
		run $tclsh $script $inputs >$target
	}
	Depends utf8.o _unicode_mapping.c
}

ArchiveLib jim jim.c jim-subcmd.c jim-interactive.c jim-format.c utf8.c jimregexp.c _loadstatic.c _initjimsh.c $extrasrcs

Executable jimsh jimsh.c

ifconfig JIM_UNIT_TESTS {
	Test --runwith=jimsh regtest.tcl
}

Generate Tcl.html make-index jim_tcl.txt {
	run $tclsh $script $inputs | asciidoc -o $target -d manpage -
}
#Install /docs Tcl.html

Depends docs Tcl.html

Clean distclean jim-config.h jimautoconf.h config.log settings.conf
