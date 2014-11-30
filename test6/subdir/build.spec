# vim:set syntax=tcl:

#Load settings.conf

CFlags -g
LinkFlags -g

IncludePaths include

Executable --install=/bin blah blah.c
Generate {blah.c include/blah.h} make-two {} {
	note "MakeTwo $target"
	puts "Creating $build/tempfile.dat"
	writefile $build/tempfile.dat "This is a temp file\n"
	run sh $script $target
} -onerror {
	note "MakeTwo failed, so cleaning up..."
	puts "file delete $build/tempfile.dat"
	file delete $build/tempfile.dat
}

# Test the -nofail support
Phony failtest -nofail -do {
	puts "About to fail"
	error "from first command"
}
Phony failtest -add -do {
	error "from second command"
}
