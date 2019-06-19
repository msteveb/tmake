# This test shows how to easily add a regexp-based dyndep rule

# Note that we currently don't support INCPATHS
Generate test1.out parser test1.in {
	run $script $inputs >$target
} -dyndep {
	parser-dyndep-scan $PARSER_INC_PATTERN
}

PublishBin --script parser

Depends all [make-local test1.out]
