#include <stdio.h>
#include <unistd.h>

#include "timerqueue.h"
#include "fdcallback.h"
#include "timer.h"

static int done = 0;

static void timer_20ms_callback(struct timerqueue_t *tq, void *cookie)
{
	putchar('.');
	fflush(stdout);

	/* And reschedule */
	timer_queue_add(tq, 20, timer_20ms_callback, cookie);
}

static void timer_100ms_callback(struct timerqueue_t *tq, void *cookie)
{
	static int count;

	putchar('!');
	fflush(stdout);

	if (++count >= 3) {
		done = 1;
	}
	else {
		/* And reschedule */
		timer_queue_add(tq, 100, timer_100ms_callback, cookie);
	}
}

static void stdin_read(struct fd_callback_s *cb)
{
	char ch;
	if (read(cb->fd, &ch, 1) == 1) {
		printf("[%c]", ch);
		fflush(stdout);
	}
}

int main(int argc, char *argv[])
{
	struct timeval timeout;

	struct timerqueue_t *tq = timer_queue_alloc();

	/* Add some timer tasks and some fd tasks */
	timer_queue_add(tq, 20, timer_20ms_callback, "20ms timer");
	add_callback(fileno(stdin), stdin_read, NULL, "reader", "stdin reader");

	/* We want this one to fire immediately, so call it. It will re-add itself */
	timer_100ms_callback(tq, "100ms timer");

	while (!done) {
		int need_timeout = !timer_queue_get_timeout(tq, &timeout);

		fd_callbacks_select(need_timeout ? &timeout : NULL);

		timer_queue_check_events(tq);
	}
	printf("\n");

	timer_queue_free(tq);

	return(0);
}
