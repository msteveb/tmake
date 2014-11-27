CFlags -DPROCESSOR_VERSION="processor\\ v1.0"
#CFlags -DPROCESSOR_VERSION="def"

# XXX: If cross compiling, should use HostExecutable here
Executable processor processor.c

foreach infile [Glob *.in] {
	set outfile [file rootname $infile]
	Generate $outfile processor $infile {
		run $script $inputs $target
	}
	Depends all [make-local $outfile]
}
