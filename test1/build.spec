# vim:set syntax=tcl:

#Load settings.conf

IncludePaths include
CFlags -g
LinkFlags -g
Lib timer timerqueue.c timer.c
Executable --test testfdloop testfdloop.c fdcallback.c

target {blah.c include/blah.h} -depends make-two -vars basename blah -do {
	note "MakeTwo $target"
	writefile tempfile.dat "This is a temp file"
	run sh make-two $basename
} -onfail {
	note "MakeTwo failed, so cleaning up..."
} -clean tempfile.dat
Clean clean blah.c include/blah.h

Executable blah blah.c
