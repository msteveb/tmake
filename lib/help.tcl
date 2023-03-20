# Copyright (c) 2011 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module which provides version, usage, help

proc show-version {} {
    return "tmake v$::tmake(version)"
}

proc max {a b} {
    expr {$a > $b ? $a : $b}
}

proc options-wrap-desc {text length firstprefix nextprefix initial} {
    set len $initial
    set space $firstprefix
    foreach word [split $text] {
        set word [string trim $word]
        if {$word == ""} {
            continue
        }
        if {$len && [string length $space$word] + $len >= $length} {
            puts ""
            set len 0
            set space $nextprefix
        }
        incr len [string length $space$word]
        puts -nonewline $space$word
        set space " "
    }
    if {$len} {
        puts ""
    }
}

# Display options (list is a list of {option help ...}
proc options-show {list} {
    set local 0
    # Determine the max option width
    set max 0
    foreach {opt desc} $list {
        if {[string match =* $opt] || [string match \n* $desc]} {
            continue
        }
        set max [max $max [string length $opt]]
    }
    set indent [string repeat " " [expr {$max+4}]]
    set cols [getenv COLUMNS 80]
    catch {
        lassign [exec stty size] rows cols
    }
    incr cols -1
    # Now output
    foreach {opt desc} $list {
        puts -nonewline "  [format %-${max}s $opt]"
        if {[string match \n* $desc]} {
            # Output a pre-formatted help description as-is
            puts $desc
        } else {
            options-wrap-desc [string trim $desc] $cols "  " $indent [expr {$max+2}]
        }
    }
}

proc show-help {argv arg} {
    puts {Usage: tmake [options] [name=value ...] [targets]}
    puts "\ntmake builds projects based on simple, flexible build descriptions.\n"

    options-show  {
        {-h|--help[=all]}      {Show this help, or with --help=all, show uncommon options too.}
        {--configure ...}      {Run autoconfiguration (if supported by the project) with the given options}
        {--warnings}           {Output saved warning messages (for any targets that would be built)}
        {-v|--verbose}         {Force "V=1" mode when building to show commands executed (also try -v -v)}
        {-n|--dry-run}         {Show commands which would have been run, but don't execute}
        {--force}              {Treat all targets to be built as out-of-date}
        {-t|--time}            {Show build time even if nothing was run}
        {-q|--quickstop}       {Stop on the first build error}
        {-Q|--quiet}           {Don't show the build time}
        {--targets[=all]}      {List all non-phony targets. If a parameter is given, include all targets and the rule location.}
        {--find[=<target>]}    {Show all rules, or those that contain the given substring as a target}
        {--jobs=<n>}           {Limit parallel jobs to <n>. Defaults to the number of cpus, or $MAXJOBS if set}
        {--genie}              {Generate an initial build.spec from sources in the current dir}
        {--commands[=names]}   {Show commands from the rulebase, or just the given command}
        {-d...}                {Enable various debugging "types"}
        {-d?}                  {Show all individual debugging types}
        {--debug}              {Alternative to "-dg"}
        {--showcache}          {Dump the tmake cache in a readable form}
        {--build=<objdir>}     {Specify the directory for build results (default: objdir)}
        {--install=<dir>}      {Install tmake to the given directory as a single script: <dir>/tmake}
        {--version}            {Show the tmake version}
        {--rulebase}           {Output the builtin rulebase}
        {--ref|--man}          {Show developer reference manual}
    }
    if {$arg ne ""} {
        options-show {
            {--findall=<target>}   {Like --find, but show all matches, even if there is an exact match}
            {-C|--directory=<dir>}  {Run as if from directory <dir>}
            {-N|-nn}               {Like -n, but don't show detailed commands}
            {--col}                {Colour output even if stdout doesn't appear to be a terminal}
            {--nocol}              {Don't colour output even if stdout appears to be a terminal}
            {--nopager}            {Don't use a pager when displaying the reference manual}
            {--delta}              {Use with -dT to show delta times}
            {--showvars?=where?}   {Show the value of each defined variable, and location if =where is specified}
            {--showaliases}        {List all aliases defined in the build specification}
            {--hash}               {Force 'UseHashes on'}
        }
    }
    puts ""
    puts [show-version]
    exit 0
}

# If not already paged and stdout is a tty, pipe the output through the pager
# This is done by reinvoking the commandline with --nopager added
proc use_pager {} {
    if {$::tmake(usepager) && [getenv PAGER ""] ne "" && [isatty? stdin] && [isatty? stdout]} {
        if {[catch {
            exec [info nameofexecutable] $::argv0 --nopager --col {*}$::argv |& {*}[getenv PAGER] >@stdout <@stdin 2>@stderr
        } msg opts] == 1} {
            if {[dict get $opts -errorcode] eq "NONE"} {
                # an internal/exec error
                puts stderr $msg
                exit 1
            }
        }
        exit 0
    }
}

proc help-select-formatter {type} {
    switch -glob -- $type {
        wiki {use wiki-formatting}
        ascii* {use asciidoc-formatting}
        md - markdown {use markdown-formatting}
        default {use text-formatting}
    }
}

# Outputs the reference manual in one of several formats
proc show-reference {{type text}} {

    use_pager
    help-select-formatter $type

    title "[show-version] -- Command Reference"

    section {Introduction}

    p {
        See https://dev.workware.net.au/git/?p=tmake.git;a=summary for the online documentation for 'tmake'
    }

    p {
        'tmake' is a concept build system. It is used as a test bench
        for various ideas for a simple but powerful build system, while
        also being useful for real-world projects.

        'tmake' is not yet ready for public consumption. It lacks a number
        of key features and much documentation.
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
        # External rulebase
        lappend files [lindex $rulebase 0]
    }

    section "Core Commands"

    foreach file $files {
        show-command-reference-blob [file rootname [file tail $file]] [readfile $file]
    }

    if {[llength $rulebase] > 1} {
        # Default/internal rulebase
        show-command-reference-blob {*}$rulebase
    }
    exit 0
}

# combine type, text into the current command help dictionary
proc add-cmd-help {&dict type text} {
    if {$text eq "" || $dict(type) ne $type} {
        if {[llength [dict-getdef $dict lines {}]]} {
            lappend dict(blocks) $dict(type) $dict(lines)
        }
        dict set dict type $type
        if {$text eq ""} {
            dict set dict lines {}
        } else {
            dict set dict lines [list $text]
        }
    } else {
        lappend dict(lines) $text
        #puts [list * $type $text]
        #parray dict
    }
    if 0 {
        if {$t ne $type || $desc eq ""} {
            if {$cmd eq ""} {
                if {[llength $lines]} {
                    error "Got text for no command - $type $lines"
                }
            } else {
                # Finish the current block
                lappend cmdinfo($cmd) [list $type $lines]
            }
            set lines {}
            set type $t
        }
        if {$desc ne ""} {
            lappend lines $desc
        }
    }
}

proc show-command-reference-blob {name text} {
    set searching 1
    set lines {}
    set type p
    # dictionary of subsection (command) name -> {type lines} ...
    set cmdinfo {}

    # This is the current command help info.
    # It is a dictionary of name=cmd name, type=current type, lines=current lines, blocks=list of {type lines ...}
    set current {}

    foreach line [split $text \n] {
        if {$searching} {
            # Find lines starting with "# @*" and continuing through the remaining comment lines
            if {![regexp {^# @(.*)} $line -> cmd]} {
                continue
            }
            set searching 0

            # Synopsis or command?
            if {$cmd eq "synopsis:"} {
                set current [dict create name "Module: $name" section section type p lines {} blocks {}]
            } else {
                if {[dict exists $current name]} {
                    error "Got command $cmd while previous command was pending"
                }
                # Command with no description yet
                set current [dict create name $cmd section subsection type p lines {} blocks {}]
            }
            continue
        }

        # Now the description
        if {![regexp {^#(#)? ?(.*)} $line -> hash desc]} {
            # Not a command description line, so finish current if started
            add-cmd-help current "" ""
            if {[dict exists $current name]} {
                dict set cmdinfo [dict get $current name] [list [dict get $current section] [dict get $current blocks]]
            }
            set current {}
            set searching 1
        } else {
            if {$hash eq "#"} {
                add-cmd-help current code $desc
            } elseif {[regexp {^- (.*)} $desc -> desc]} {
                add-cmd-help current list $desc
            } else {
                add-cmd-help current p $desc
            }
        }

    }

    add-cmd-help current "" ""

    # Now output in sorted order
    foreach cmd [lsort [dict keys $cmdinfo]] {
        lassign [dict get $cmdinfo $cmd] section blocks
        $section $cmd
        foreach {type lines} $blocks {
            output-help-block $type $lines
        }
    }
}
