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
   -d...                 Enable various debugging "types"
   -d?                   Show all individual debugging types
   --debug               Alternative to "-dg"
}
	puts [show-version]
	exit 0
}
