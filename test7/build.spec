# XXX: If cross compiling, should use HostExecutable here
Executable processor processor.c

foreach infile [Glob *.in] {
	set outfile [file rootname $infile]
	Generate $outfile processor $infile {
		run $script $inputs $target
	}
	Depends all [make-local $outfile]
}
