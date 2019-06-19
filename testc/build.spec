# Note that <bin>parser and subdir/test1.in are both dependencies of top.out
# but only $inputs are scanned, not $depends
Generate top.out <bin>parser subdir/test1.in {
	run $script $inputs >$target
} -dyndep {
	parser-dyndep-scan $PARSER_INC_PATTERN
}

Depends all [make-local top.out]
