Lib --publish my_static_lib test_staticlib.c

Executable main main.c

Generate foo.h {} {} {
	sleep 1
	writefile $target "\n"
}
