# To compile in C++ mode
# CFlags -xc++

Executable calc main.c calc.y calc.l

# To build a library from calc.y and calc.l that can be used
# in other applications
# Lib --publish calc calc.y calc.l
# Executable calc main.c
