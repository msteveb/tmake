# This test shows how to easily add a regexp-based dyndep rule

# Note that we currently don't support INCPATHS
Generate test1.out parser test1.in {
	run $script $inputs >$target
} -dyndep {
	# We use the path to the first file as INCPATH
	header-scan-regexp-recursive [file dirname [lindex $inputs 0]] "" $PARSER_INC_PATTERN
}

PublishBin --script parser

Depends all [make-local test1.out]
