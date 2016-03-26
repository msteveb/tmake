# Simple command line argument parser

# Usage: argparse argv { patterns code patterns code ... }
#
# The code is evaluated if the arg matches a correponding glob pattern
# The current argument is available as $arg
# Call [argnext argv] to get the next arg.
# Call [argparse $arg] to get the next arg.
# Leaves $argv with unconsumed args.

proc argparse {&argv spec} {
	# Make the arg available in the calling context
	upvar arg arg

	if {[exists arg]} {
		error "Variable arg already exists in calling context"
	}
	if {[llength $spec] == 1} {
		set spec [lindex $spec 0]
	}

	# Get the next arg from argv and return it
	local proc argnext {&argv} {
		# Remove an arg and return following one
		set argv [lassign $argv arg]
		return [lindex $argv 0]
	}
	# Extract the value from --option=value
	local proc argparam {arg} {
		if {[regexp {^(-+[^=]*)(=)?(.*)?} $arg -> option equals value]} {
			return $value
		}
		error "Can't find parameter from $arg"
	}

	set done 0
	while {[llength $argv]} {
		set arg [lindex $argv 0]
		set matched 0
		foreach {patterns code} $spec {
			foreach pattern $patterns {
				if {[string match $pattern $arg]} {
					incr matched
					try {
						uplevel 1 $code
					} on break {} {
						incr done
					}
					break
				}
			}
			if {$matched} {
				# consume it
				argnext argv
				break
			}
		}
		# Stop once something doesn't match
		if {!$matched || $done} {
			break
		}
	}
	# argv now contains all unconsumed args
}
