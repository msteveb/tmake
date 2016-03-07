#include <string.h>
#include "config.h"

int main(int argc, char **argv)
{
#ifndef BE_TRUE
	return 1;
#else
	return strcmp(var, "mystring");
#endif
}
