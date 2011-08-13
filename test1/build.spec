#Load settings.conf

CFlags -g -I.
LinkFlags -g
Lib timer timerqueue.c timer.c
Executable --test testfdloop testfdloop.c fdcallback.c
