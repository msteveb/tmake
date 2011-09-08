#include <stdio.h>
#include <sys/times.h>
#ifdef __linux__
#include <sys/sysinfo.h>
#endif
#include <unistd.h>
#include "timer.h"

/**
 * Code taken from timerqueue.c
 */
struct timeval timer_get(void)
{
	struct timeval now;

#ifdef __linux__
	static clock_t last_times;
	static long adjust_seconds;
	static int calibrated;
#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC 1000
#endif
	static long sc_clk_tck = CLOCKS_PER_SEC;

	clock_t now_times = times(NULL);

	if (!calibrated || now_times < last_times) {
		/* Wrap around or initia calibration, so use sysinfo() to help us
		 * know how much to adjust by
		 */
		struct sysinfo si;

		sysinfo(&si);

		/* And set sc_clk_tck while we are here */
		sc_clk_tck = sysconf(_SC_CLK_TCK);

		/* si.uptime and now_times / sc_clk_tck should be equivalent, just with
		 * a different base
		 */
		adjust_seconds = si.uptime - (now_times/ sc_clk_tck);

		calibrated = 1;
	}

	now.tv_sec = adjust_seconds + (now_times / sc_clk_tck);
	now.tv_usec = (now_times % sc_clk_tck) * (1000000L / sc_clk_tck);

	last_times = now_times;
#else

	gettimeofday(&now, NULL);

	return now;

#endif

	return now;
}

struct timeval timer_diff(const struct timeval larger, const struct timeval smaller)
{
	struct timeval tv;

	tv.tv_sec = larger.tv_sec - smaller.tv_sec;
	if (larger.tv_usec < smaller.tv_usec) {
		tv.tv_usec = 1000000L + larger.tv_usec - smaller.tv_usec;
		tv.tv_sec--;
	}
	else {
		tv.tv_usec = larger.tv_usec - smaller.tv_usec;
	}
	return(tv);
}

unsigned long timer_ms(const struct timeval tv)
{
	return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

unsigned long timer_diff_ms(const struct timeval larger, const struct timeval smaller)
{
	return timer_ms(timer_diff(larger, smaller));
}

struct timeval timer_lap(const char *message, struct timeval prev)
{
	struct timeval now = timer_get();
	struct timeval diff = timer_diff(now, prev);

	fprintf(stderr, "%6ld.%03ld ms %s\n", (long)diff.tv_sec * 1000 + (long)diff.tv_usec / 1000, (long)diff.tv_usec % 1000, message);

	return now;
}
