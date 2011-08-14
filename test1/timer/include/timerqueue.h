#ifndef TIMERQUEUE_H
#define TIMERQUEUE_H

/**
 * Implements a queue of events which should be triggered
 * at a particular time.
 */

#include <sys/time.h>

struct timerqueue_t;
typedef void timerqueue_callback_t(struct timerqueue_t *timerqueue, void *cookie);

/**
 * Allocates a timer queue.
 */
struct timerqueue_t *timer_queue_alloc(void);

/**
 * Frees a previously allocated timer queue.
 */
void timer_queue_free(struct timerqueue_t *tq);

/**
 * Add a callback to the timer queue.
 * 
 * 'callback' will be invoked after 'ms' milliseconds (from now).
 * 'cookie' will be passwed to 'callback'
 */
void timer_queue_add(struct timerqueue_t *tq, unsigned long ms, timerqueue_callback_t *callback, void *cookie);

/**
 * For all events which have expired, invoke the 'callback' function
 * and remove from the queue.
 */
void timer_queue_check_events(struct timerqueue_t *tq);

/**
 * Get the timeout represented by the nearest event.
 *
 * This means tv = (nearest - now).
 * If the event time has already passed for the nearest event,
 * returns, 'tv' is set to 0.
 * 
 * Returns 0 if at least one entry is in the queue, or 1 if the
 * queue is empty (and tv is unchanged);
 */
int timer_queue_get_timeout(struct timerqueue_t *tq, struct timeval *tv);

#endif
