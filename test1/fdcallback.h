#ifndef FDCALLBACK_T
#define FDCALLBACK_T

#include <sys/time.h>

struct fd_callback_s;
typedef void fd_callback_function(struct fd_callback_s *cb);

typedef struct fd_callback_s {
	int fd;					/* File descriptor to listen on */
	int read;				/* Set to listen for read */
	int write;				/* Set to listen for write */
	fd_callback_function *read_callback;		/* Callback when fd is readable */
	fd_callback_function *write_callback;		/* Callback when fd is writable */
	void *cookie;								/* User data */
	const char *name;		/* Name for this registration (for debugging) */
} fd_callback_t;

#define MAX_FD_CALLBACKS 20

/**
 * Add read and/or write callbacks on the given file descriptor.
 * If either callback is NULL, it is not added.
 *
 * Returns the callback entry.
 */
fd_callback_t *add_callback(int fd, fd_callback_function *read_callback, fd_callback_function *write_callback, void *cookie, const char *name);

/**
 * Removes the given callback entry.
 */
void remove_callback(fd_callback_t *cb);

/**
 * Calls select() on all active fds with the given timeout (may be 0).
 * and then calls all appropriate callbacks.
 */
int fd_callbacks_select(struct timeval *timeout);

#endif
