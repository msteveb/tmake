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
   -t|--time             Show build time even if nothing was run
   -q|--quickstop        Stop on the first build error
   -Q|--quiet            Don't show the build time
   -p|--print            Output all known rules
   --genie               Generate an initial build.spec from sources in the current dir
   -d...                 Enable various debugging "types"
   -d?                   Show all individual debugging types
   --debug               Alternative to "-dg"
   --showcache           Dump the tmake cache in a readable form
   --find=<target>       Search for all rules that contain given substring as a target
   --delta               Show times as delta times rather than absolute times
   --build=<objdir>      Specify the directory for build results (default: objdir)
   --targets[=1]         List all known targets. If a parameter is given, include the rule location.
   --install             Install tmake to the current directory (as autosetup/tmake)
   --init                Run only the parsing phase??
   --version             Show the tmake version
   --genie               Create sample project.spec and build.spec files
}
	puts [show-version]
	exit 0
}
