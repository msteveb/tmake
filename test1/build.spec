# vim:set syntax=tcl:

#Load settings.conf

CFlags -g
LinkFlags -g
IncludePaths publish/include

# This simulates what will happen once we have subdir support
PublishIncludes fdcallback/fdcallback.h

PublishIncludes [prefix timer/include/ timer.h timerqueue.h]

# Imagine that we want to build one object with different flags
ObjectCFlags [Object timer/timerqueue.o timer/timerqueue.c] -DDUMMY_DEFINE
# And specify the object file here
Lib --publish timer/timer timer/timer.c timer/timerqueue.o

Executable --publish --test testfdloop testfdloop.c fdcallback/fdcallback.c

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
