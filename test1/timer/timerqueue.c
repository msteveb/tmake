#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>
#ifdef __linux__
#include <sys/sysinfo.h>
#endif
#include <sys/times.h>

#include "timerqueue.h"
#include "timer.h"

typedef struct timer_event_s {
	struct timer_event_s *next;
	struct timeval tv;
	timerqueue_callback_t *callback;
	void *cookie;
} timer_event_t;

struct timerqueue_t {
	/* Singly linked list of events with the nearest first.
	 * The first entry is a dummy entry
	 */
	timer_event_t events;
};

/**
 * Compare two timevals.
 *
 * Returns 0 if equal, < 0 if tv1 < tv2, and > 0 if tv1 > tv2.
 */
static int compare_tv(const struct timeval *tv1, const struct timeval *tv2)
{
	if (tv1->tv_sec == tv2->tv_sec) {
		return(tv1->tv_usec - tv2->tv_usec);
	}
	return(tv1->tv_sec - tv2->tv_sec);
}

/**
 * Add the given number of milliseconds to the timeval.
 */
static void add_tv(struct timeval *tv, unsigned long ms)
{
	/* Add and normalise */
	tv->tv_usec += (ms % 1000L) * 1000L;
	tv->tv_sec += ms / 1000L;
	tv->tv_sec += tv->tv_usec / 1000000L;
	tv->tv_usec = tv->tv_usec % 1000000L;
}

struct timerqueue_t *timer_queue_alloc()
{
	struct timerqueue_t *tq = malloc(sizeof(*tq));

	tq->events.next = NULL;
	tq->events.callback = NULL;
	tq->events.cookie = NULL;

	return(tq);
}

void timer_queue_free(struct timerqueue_t *tq)
{
	while (tq->events.next) {
		timer_event_t *e = tq->events.next;
		
		tq->events.next = e->next;

		free(e);
	}
	free(tq);
}

void timer_queue_add(struct timerqueue_t *tq, unsigned long ms, timerqueue_callback_t *callback, void *cookie)
{
	timer_event_t *ee;
	timer_event_t *e = malloc(sizeof(*e));
	e->callback = callback;
	e->cookie = cookie;

	e->tv = timer_get();

	/* Add the offset and normalise */
	add_tv(&e->tv, ms);

	/* Now insert it in the correct location */
	for (ee = &tq->events; ee->next; ee = ee->next) {
		if (compare_tv(&e->tv, &ee->next->tv) < 0) {
			/* Need to insert it between ee and ee->next */
			break;
		}
	}
	e->next = ee->next;
	ee->next = e;
}

void timer_queue_check_events(struct timerqueue_t *tq)
{
	struct timeval now;
	timer_event_t *ee;

	now = timer_get();

	for (ee = &tq->events; ee->next; ) {
		if (compare_tv(&ee->next->tv, &now) <= 0) {
			timer_event_t *e;
			/* Invoke the event callback */
			struct timeval t = timer_get();
			ee->next->callback(tq, ee->next->cookie);
			if (timer_ms(timer_diff(timer_get(), t)) > 10) {
				timer_lap("timer callback took too long", t);
			}

			/* And remove this entry */
			e = ee->next;
			ee->next = ee->next->next;
			free(e);
		}
		else {
			ee = ee->next;
		}
	}
}

int timer_queue_get_timeout(struct timerqueue_t *tq, struct timeval *tv)
{
	struct timeval now;

	if (!tq->events.next) {
		return(1);
	}
	now = timer_get();

	timerclear(tv);

	if (compare_tv(&tq->events.next->tv, &now) > 0) {
		tv->tv_sec = tq->events.next->tv.tv_sec - now.tv_sec;
		if (tq->events.next->tv.tv_usec < now.tv_usec) {
			tv->tv_usec = 1000000L + tq->events.next->tv.tv_usec - now.tv_usec;
			tv->tv_sec--;
		}
		else {
			tv->tv_usec = tq->events.next->tv.tv_usec - now.tv_usec;
		}
	}
	return(0);
}
