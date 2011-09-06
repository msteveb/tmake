Executable processor processor.c

foreach infile [glob-src *.in] {
	set outfile [file rootname $infile]
	Generate $outfile processor $infile {
		run $script $inputs $target
	}
	Depends [make-local all] [make-local $outfile]
}
