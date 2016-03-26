CFlags -DTEST

Object b1.o b.c
Executable a a.c b1.o test*.c

CFlags -DTEST2

Object b2.o b.c
Executable a2 a2.c b2.o
