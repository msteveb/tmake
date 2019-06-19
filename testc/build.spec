Generate top.out <bin>parser subdir/test1.in {
	run $script $inputs >$target
} -dyndep {
	# We use the path to the first file as INCPATH
	# PARSER_INC_PATTERN is defined in project.spec
	header-scan-regexp-recursive [file dirname [lindex $inputs 0]] "" $PARSER_INC_PATTERN
}

Depends all [make-local top.out]
