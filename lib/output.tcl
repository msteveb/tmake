# Copyright (c) 2007 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# Module to manage output to files
# We buffer ouput as lines and then write it out at the end

proc output_close {filename} {
	dputs "output_close '$filename'"

	if {$::automf(cleaning)} {
		delete_automf_makefile $filename
	} else {
		dputs "Creating $filename ([llength [local_var lines]] lines)"
		set fd [create_automf_makefile $filename]
		puts $fd [join [local_var lines] \n]
		close $fd
	}
	local_set lines {}
}

proc output_discard {} {
	dputs "output_discard"
	local_set lines {}
}

proc output_blank {} {
	local_set needblank 1
}

# Outputs newline-separated lines
proc output {msg} {
	if {$::automf(cleaning)} {
		return
	}
	if {![local_var allowed]} {
		user_error "output is not allowed from the project.spec file, use the top level build.spec instead"
	}

	if {[local_var needblank]} {
		local_lappend lines ""
		local_set needblank 0
	}
	local_lappend lines $msg
}

# Outputs a list of lines
proc output_lines {lines} {
	foreach line [split $lines \n] {
		output [string trim $line]
	}
}

proc allow_output {code} {
	set old [local_var allowed]
	local_set allowed 1
	uplevel 1 $code
	local_set allowed $old
}

proc disallow_output {code} {
	set old [local_var allowed]
	local_set allowed 0
	uplevel 1 $code
	local_set allowed $old
}
