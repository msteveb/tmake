CFlags -O3 -Dfoo=bar

Executable myprogram main.c

Generate b.h {} {} {
	writefile $target "int abc = 423;"
}

Generate abc.h {} {} {
	writefile $target "int kik = 343;"
}
