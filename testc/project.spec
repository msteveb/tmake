# This test shows how to easily add a regexp-based dyndep rule

# This is the regexp pattern
define PARSER_INC_PATTERN {^[\t ]*include[\t ]+([^\t ]+)}

# Custom dyndep scanner for 'parser', using header-scan-regexp-recursive
proc parser-dyndep-scan {pattern filename} {
	# Use the path to the input file as the search path
	set incpath [file dirname $filename]
	return [header-scan-regexp-recursive $incpath "" $pattern $filename]
}
