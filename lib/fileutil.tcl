# ==================================================================
# File Utilities
# ==================================================================

# @readfile filename ?default?
#
# Return the contents of the file, without the trailing newline.
# If the file doesn't exist or can't be read, returns $default.
# If no default is given, it is an error. 
#
proc readfile {filename args} {
	try {
		set f [open $filename]
		set result [read -nonewline $f]
		close $f
	} on error {msg opts} {
		if {[llength $args] != 1} {
			return -code error $msg
		}
		lassign $args result
	}
	return $result
}

# @writefile filename value
#
# Creates the given file containing $value.
# Does not add an extra newline.
#
proc writefile {filename value} {
	file mkdir [file dirname $filename]
	set f [open $filename w]
	puts -nonewline $f $value
	close $f
}

# If $file doesn't exist, or it's contents are different than $buf,
# the file is written and 1 is returned.
# Otherwise 0 is returned.
proc write-if-changed {file buf {script {}}} {
	set old [readfile $file ""]
	if {$old ne $buf || ![file exists $file]} {
		writefile $file $buf\n
		return 1
	}
	return 0
}

proc copy-if-changed {source dest} {
	write-if-changed $dest [readfile $source]
}

