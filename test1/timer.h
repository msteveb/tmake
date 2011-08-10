#ifndef TIMER_H
#define TIMER_H

#include <sys/time.h>

struct timeval timer_get(void);

/**
 * Substracts two timevals and returns the resulting timeval.
 */
struct timeval timer_diff(const struct timeval larger, const struct timeval smaller);

unsigned long timer_ms(const struct timeval tv);

unsigned long timer_diff_ms(const struct timeval larger, const struct timeval smaller);

/**
 * Subtracts 'prev' from "now" and prints a message to stderr with the resulting
 * time difference plus the given message.
 * Returns "now".
 */
struct timeval timer_lap(const char *message, struct timeval prev);

#endif
