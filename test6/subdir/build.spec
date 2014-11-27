# vim:set syntax=tcl:

#Load settings.conf

CFlags -g
LinkFlags -g

IncludePaths include

Executable --install=/bin blah blah.c
Generate {blah.c include/blah.h} make-two {} {
	note "MakeTwo $target"
	writefile tempfile.dat "This is a temp file"
	run sh $script $target
} -onerror {
	note "MakeTwo failed, so cleaning up..."
} -clean tempfile.dat

# Test the -nofail support
Phony failtest -nofail -do {
	puts "About to fail"
	error "from first command"
}
Phony failtest -add -do {
	error "from second command"
}
