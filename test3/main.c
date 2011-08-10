#include <string.h>
#include <stdlib.h>

#include <log.h>
#include <state.h>
#include <cgi.h>
#include <cgimain.h>
#include <httpmain.h>
#include <httpserver.h>

/*
 * Usage:
 *    app server [port] runs the app as a standalone web server (on the given port -- default 80)
 *    app inetd         runs the app with the builtin webserver under inetd
 *    app /page ...     runs in command line mode
 *    app               runs as a cgi app under a web server
 */
int main(int argc, char *argv[])
{
	state_t *state;

	log_init_default();
	log_set_ident(argv[0]);

	/* Load the state to see if we should enable all debug logging */
	state = uweb_state_load();
	if (state) {
		const char *enable = state_get(state, "debug.enable");
		const char *log = state_get(state, "debug.log");
		if (enable && atoi(enable)) {
			log_set_level(LOG_LEVEL_DEBUG, LOG_TARGET_STDERR | LOG_OPT_ALL, 0);
		}
		if (log && *log) {
			log_parse_env(log);
		}
		state_discard(state);
	}

	/* Show a message which will be seen if LOG=+all is set */
	log_debug("-", "Debug messages are enabled");

	if (argc > 1) {
		if (strcmp(argv[1], "server") == 0) {
			int port = (argc > 2) ? atoi(argv[2]) : 80;

			if (uweb_http_server(argv[0], port) != 0) {
				exit(1);
			}
			return uweb_http_main(argv[0]);
		}
		else if (strcmp(argv[1], "inetd") == 0) {
			return uweb_http_main(argv[0]);
		}
	}
	return uweb_cgi_main(argc, argv);
}

/* vi: se ts=4: */
