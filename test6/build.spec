# vim:set syntax=tcl:

#Load settings.conf

CFlags -g
LinkFlags -g

IncludePaths include

Executable blah blah.c
target {blah.c include/blah.h} -depends make-two -vars basename blah -do {
	note "MakeTwo $target"
	writefile tempfile.dat "This is a temp file"
	run sh make-two $basename
} -onerror {
	note "MakeTwo failed, so cleaning up..."
} -clean tempfile.dat
Clean clean blah.c include/blah.h

# Test the -nofail support
Phony failtest -nofail -do {
	puts "About to fail"
	error "from first command"
}
Phony failtest -add -do {
	error "from second command"
}
