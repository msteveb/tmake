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
   -d|--debug            Enable debugging output
   -n|--dry-run          Show commands which would have been run
}
	puts [show-version]
	exit 0
}
