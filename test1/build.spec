# vim:set syntax=tcl:

#Load settings.conf

IncludePaths include
CFlags -g
LinkFlags -g
Lib timer timerqueue.c timer.c
Executable --test testfdloop testfdloop.c fdcallback.c

target {blah.c include/blah.h} -depends make-two -vars basename blah -do {
	note "MakeTwo $target"
	run sh make-two $basename
}
Clean clean blah.c include/blah.h

Executable blah blah.c
