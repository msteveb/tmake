#include <assert.h>
#include <string.h>
#include <stdio.h>

#include "fdcallback.h"
#include "timer.h"

static int num_callbacks = 0;
static fd_callback_t fd_callbacks[MAX_FD_CALLBACKS];

fd_callback_t *add_callback(int fd, fd_callback_function *read_callback, fd_callback_function *write_callback, void *cookie, const char *name)
{
	fd_callback_t *cb = &fd_callbacks[num_callbacks];

	assert(num_callbacks < MAX_FD_CALLBACKS);

	cb->fd = fd;
	cb->read = (read_callback != NULL);
	cb->read_callback = read_callback;
	cb->write = (write_callback != NULL);
	cb->write_callback = write_callback;
	cb->cookie = cookie;
	cb->name = name ?: "unknown";

	num_callbacks++;

	return cb;
}

void remove_callback(fd_callback_t *cb)
{
	int i;

	for (i = 0; i < num_callbacks; i++) {
		if (cb == &fd_callbacks[i]) {
			/* Move everything up */
			memmove(&fd_callbacks[i], &fd_callbacks[i + 1], sizeof(*fd_callbacks) * (num_callbacks - i - 1));
			num_callbacks--;
			return;
		}
	}
	printf("Warning: remove_callback() did not find matching entry\n");
}


int fd_callbacks_select(struct timeval *timeout)
{
	int i;
	int n = 0;
	int ret;

	fd_set reads;
	fd_set writes;

	FD_ZERO(&reads);
	FD_ZERO(&writes);

	//printf("fd_callbacks_select(timeout=%ld.%03ld), num_callbacks=%d\n", timeout->tv_sec, timeout->tv_usec / 1000, num_callbacks);

	for (i = 0; i < num_callbacks; i++) {
		fd_callback_t *cb = &fd_callbacks[i];

		if (cb->read) {
			/* Add a read callback for the fd */
			FD_SET(cb->fd, &reads);
			n = (cb->fd > n) ? cb->fd : n;
			//printf("read check on fd=%d\n", cb->fd);
		}
		if (cb->write) {
			/* Add a write callback for the fd */
			FD_SET(cb->fd, &writes);
			n = (cb->fd > n) ? cb->fd : n;
			//printf("write check on fd=%d\n", cb->fd);
		}
	}

	ret = select(n + 1, &reads, &writes, 0, timeout);
	if (ret > 0) {
		/* Now call any callbacks which have fired */
		for (i = 0; i < num_callbacks; i++) {
			fd_callback_t *cb = &fd_callbacks[i];

			if (cb->read && FD_ISSET(cb->fd, &reads)) {
				struct timeval t = timer_get();

				//printf("got read on fd=%d\n", cb->fd);
				//printf("callback: read: %s\n", cb->name);
				cb->read_callback(cb);

				if (timer_ms(timer_diff(timer_get(), t)) > 10) {
					char tmp[100];
					sprintf(tmp, "read callback '%s' took too long", cb->name);
					timer_lap(tmp, t);
				}
			}
			if (cb->write && FD_ISSET(cb->fd, &writes)) {
				struct timeval t = timer_get();
				//printf("got write on fd=%d\n", cb->fd);
				//printf("callback: write: %s\n", cb->name);
				cb->write_callback(cb);
				if (timer_ms(timer_diff(timer_get(), t)) > 10) {
					char tmp[100];
					sprintf(tmp, "write callback '%s' took too long", cb->name);
					timer_lap(tmp, t);
				}
			}
		}
	}

	return ret;
}
