# vim:set syntax=tcl:

#Load settings.conf

CFlags -g -I.
LinkFlags -g
Lib timer timerqueue.c timer.c
Executable --test testfdloop testfdloop.c fdcallback.c

target {blah.c blah.h} -depends make-two -vars basename blah -do {
	note "MakeTwo $target"
	run sh make-two $basename
}
Clean clean blah.c blah.h

Executable blah blah.c
