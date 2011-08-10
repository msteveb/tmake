#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <log.h>
#include <customstorage.h>
#include <state.h>

#define STATEFILE	"/var/run/config"
#define MODFILE		"/var/run/config.modified"

static char *statefile;
static char *modfile;
static state_t* state;

// Concat root path and file and return dynamic string.
static char *get_file(char *rootpath, char *file)
{
	char *buf;
	int res = asprintf(&buf, "%s%s", rootpath ? rootpath : "", file);
	return res >= 0 ? buf : NULL;
}

// Get state pointer and do internal initialisation.
static state_t *get_state()
{
	if (!state) {
		if (!statefile) {
			char *rootpath = getenv("HOST");
			statefile = get_file(rootpath, STATEFILE);
			modfile = get_file(rootpath, MODFILE);
		}

		log_debug("state.custom", "Loading '%s'", statefile);
		state = state_load(statefile);
	}

	return state;
}

// Called for every get.
const char *custom_storage_get(const char *name)
{
	const char *value = state_get(get_state(), name);
	log_debug("state.custom", "get '%s' => '%s'", name, value);
	return value;
}

// Called once at start of sets.
void custom_storage_init_save(void)
{
	get_state();
}

// Called for every set.
int custom_storage_set(const char *name, const char *value)
{
	return state_set(state, name, value);
}

// Called once at end of sets.
int custom_storage_save(void)
{
	int result = state_store(state);

	// Set indicator file if something changed
	if (result == 1) {
		FILE *fd = fopen(modfile, "w");
		if (fd) {
			fclose(fd);
		}
	}

	state_discard(state);
	state = NULL;

	return result;
}

void custom_storage_discard(void)
{
	if (state) {
		state_discard(state);
		state = NULL;
	}
}

/* vim: se ts=4: */
