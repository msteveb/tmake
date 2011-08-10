Load settings.conf

CFlags -g
LinkFlags -g
ArchiveLib timer timerqueue.c timer.c
Executable --test testfdloop testfdloop.c fdcallback.c
