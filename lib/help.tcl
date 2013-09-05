# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides version, usage, help

proc show-version {} {
	return "tmake v$::tmake(version)"
}

proc show-help {argv} {
	puts \
{Usage: tmake [options] [targets]

   tmake builds projects based on simple, flexible build descriptions.

   -h|--help             This help, or help for the specified rule
   -C|--directory=<dir>  Run as if from directory <dir>
   -v|--verbose          Force V=1 mode when building to show commands executed
   -n|--dry-run          Show commands which would have been run
   -N                    Like -n, but don't show detailed commands
   --force               Treat all targets to be built as out-of-date
   -t|--time             Show build time even if nothing was run
   -q|--quickstop        Stop on the first build error
   -Q|--quiet            Don't show the build time
   -p|--print            Output all known rules
   --genie               Generate an initial build.spec from sources in the current dir
   --ref                 Show command reference
   -d...                 Enable various debugging "types"
   -d?                   Show all individual debugging types
   --debug               Alternative to "-dg"
   --showcache           Dump the tmake cache in a readable form
   --find=<target>       Search for all rules that contain given substring as a target
   --delta               Show times as delta times rather than absolute times
   --build=<objdir>      Specify the directory for build results (default: objdir)
   --targets[=all]       List all non-phony targets. If a parameter is given, include all targets and the rule location.
   --install=<dir>       Install tmake to the given directory
   --init                Run only the parsing phase??
   --version             Show the tmake version
   --rulebase            Output the builtin rulebase
   --genie               Create sample project.spec and build.spec files
}
	puts [show-version]
	exit 0
}

# Outputs the references manual in one of several formats
proc show-reference {{type text}} {

    #use_pager

    switch -glob -- $type {
        wiki {use wiki-formatting}
        ascii* {use asciidoc-formatting}
        md - markdown {use markdown-formatting}
        default {use text-formatting}
    }

    title "[show-version] -- Command Reference"

    section {Introduction}

    p {
        See http://xxx/ for the online documentation for 'tmake'
    }

    p {
        'autosetup' provides a number of built-in commands which
        are documented below. These may be used from 'auto.def' to test
        for features, define variables, create files from templates and
        other similar actions.
    }

    show-command-reference

    exit 0
}

proc output-help-block {type lines} {
    if {[llength $lines]} {
        switch $type {
            code {
                codelines $lines
            }
            p {
                p [join $lines]
            }
            list {
                foreach line $lines {
                    bullet $line
                }
                nl
            }
        }
    }
}

# Generate a command reference from inline documentation
proc show-command-reference {} {
    lappend files $::tmake(exe)
    lappend files {*}[lsort [glob -nocomplain $::tmake(dir)/lib/*.tcl]]

    set rulebase [get-rulebase]
    if {[llength $rulebase] == 1} {
        lappend files [lindex $rulebase 0]
    }

    section "Core Commands"
    set type p
    set lines {}
    set cmd {}

    foreach file $files {
        show-command-reference-blob [file rootname [file tail $file]] [readfile $file]
    }
    if {[llength $rulebase] > 1} {
        show-command-reference-blob {*}$rulebase
    }
    exit 0
}

proc show-command-reference-blob {name text} {
    set searching 1
    set lines {}
    set type p

    foreach line [split $text \n] {
        if {$searching} {
            # Find lines starting with "# @*" and continuing through the remaining comment lines
            if {![regexp {^# @(.*)} $line -> cmd]} {
                continue
            }
            set searching 0

            # Synopsis or command?
            if {$cmd eq "synopsis:"} {
                section "Module: $name"
            } else {
                subsection $cmd
            }

            set lines {}
            set type p
            continue
        }

        # Now the description
        if {![regexp {^#(#)? ?(.*)} $line -> hash cmd]} {
            set searching 1
            continue
        }
        if {$hash eq "#"} {
            set t code
        } elseif {[regexp {^- (.*)} $cmd -> cmd]} {
            set t list
        } else {
            set t p
        }

        #puts "hash=$hash, oldhash=$oldhash, lines=[llength $lines], cmd=$cmd"

        if {$t ne $type || $cmd eq ""} {
            # Finish the current block
            output-help-block $type $lines
            set lines {}
            set type $t
        }
        if {$cmd ne ""} {
            lappend lines $cmd
        }
    }

    output-help-block $type $lines
}
