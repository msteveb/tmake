#include <stdio.h>

/* A simple generator */
int main(void)
{
	int c;
	printf("/* Generated at %s by %s */\n", __DATE__, __FILE__);
	while ((c = getchar()) != EOF) {
		putchar(c);
	}
	return 0;
}
