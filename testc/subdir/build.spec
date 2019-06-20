# This test shows how to easily add a regexp-based dyndep rule

# Note that we use <bin>parser here rather than parser so
# that we pick up the dyndep rule for <bin>parser
Generate test1.out <bin>parser test1.in {
	setenv JIMLIB $local
	run $script $inputs >$target
} -dyndep {
	parser-dyndep-scan $PARSER_INC_PATTERN
}

# Must copy when publishing to correctly handle additional dependencies
PublishBin --script --copy parser

# XXX This is a bit ugly
target $PUBLISH/bin/parser -dyndep {
	tcl-dyndep-scan $local
}

Depends all [make-local test1.out]
