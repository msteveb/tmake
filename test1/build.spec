# vim:set syntax=tcl:

#Load settings.conf

CFlags -g
LinkFlags -g
IncludePaths publish/include

# This simulates what will happen once we have subdir support
PublishIncludes fdcallback/fdcallback.h

PublishIncludes [prefix timer/include/ timer.h timerqueue.h]

# Do this after libcdcb.a so we are sure to pick up the published versions
#IncludePaths timer/include
Lib --publish timer/timer timer/timerqueue.c timer/timer.c

Executable --publish --test testfdloop testfdloop.c fdcallback/fdcallback.c

IncludePaths include
Executable blah blah.c
target {blah.c include/blah.h} -depends make-two -vars basename blah -do {
	note "MakeTwo $target"
	writefile tempfile.dat "This is a temp file"
	run sh make-two $basename
} -onfail {
	note "MakeTwo failed, so cleaning up..."
} -clean tempfile.dat
Clean clean blah.c include/blah.h

