#define _GNU_SOURCE
#define _XOPEN_SOURCE
#include <stdio.h>
#include <string.h>
#include <log.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>

#include <cgi.h>
#include <dbstate.h>
#include <cgipage.h>
#include <cgiauth.h>
#include <cgitcl.h>

#define USERDB "/etc/config/users"
#define USERTABLE "users"

// Environment variable to allow fake user login for testing
#define FAKEUSER "REMOTE_USER"

// Return a handle to the users db. We just return the open handle and
// leave it open for the life of this process.
static dbstate_t *getdb(void)
{
	static dbstate_t *db;

	if (!db) {
		char *rootpath = getenv("HOST");
		char *dbname;
		if (asprintf(&dbname, "%s%s", rootpath ? rootpath : "", USERDB) >= 0) {
			db = dbstate_open(dbname);
			free(dbname);
		}
	}

	return db;
}

// Fetch specified field from user database for given user.
// NOTE: Returns dynamic string which caller must free().
static char *get_user_field(const char *username, const char *field)
{
	dbstate_t *db = getdb();
	return db ? dbstate_get_row_value(db, USERTABLE, username, field) : NULL;
}

const char *auth_get_username(void)
{
	/* The easiest way to do this is in Tcl */
	cgi_tcl_eval("package require auth; auth_get_username", 1);

	/* No need to make a copy. The only time this variable will change is when we come back here */
	return cgi_tcl_getvar("auth_username");
}

// Check whether the specified user is a valid user.
// 1 - the user is valid.
// 0 - the user is not valid.
int auth_user_ok(const char *username, const char *password)
{
	int valid = 0;

	// Allow fake user for testing etc
	const char *fakeuser = getenv("REMOTE_USER");
	if (fakeuser && strcmp(fakeuser, username) == 0) {
		log_debug("auth", "User %s ok to login with any password\n", fakeuser);
		valid = 1;
	}
	else if (!password) {
		/* Not valid */
	}
	else if (strcmp(username, "root") == 0 || strcmp(username, "support") == 0) {
		/* Special case for built-in users */
		struct passwd *pw = getpwnam(username);
		if (pw) {
			valid = strcmp(pw->pw_passwd, crypt(password, pw->pw_passwd)) == 0;
		}
	}
	else {
		char *pw_passwd = get_user_field(username, "password");
		if (pw_passwd) {
			valid = strcmp(pw_passwd, crypt(password, pw_passwd)) == 0;
		}
		free(pw_passwd);
	}

	log_debug("auth", "User %s %s to login\n", username, valid ? "ok" : "failed");

	return valid;
}

// Maps the current username into a role.
const char *auth_get_role(void)
{
	if (cgi_auth_status() == auth_status_ok) {

		const char *user = cgi_auth_username();

		// Handle special case for built-in users
		if (strcmp(user, "root") == 0) {
			return "factory";
		}
		else if (strcmp(user, "support") == 0) {
			return "support";
		}
		else {
			// Return dynamic string and just free it before each time we want
			// to reuse it.
			static char *role;
			free(role);
			return role = get_user_field(cgi_auth_username(), "role");
		}
	}

	return "nobody";
}

// If the user has been authed, then we can check what type of permissions
// the user should have for this page.
page_access_t auth_get_page_permissions(const char *pagename, access_action_t action)
{
	const char *role = auth_get_role();

	// Special visibility rules for some pages
	if (action == access_action_refer) {
		// Logged in users don't see login in the menu, but logged out users do
		if (strcmp(pagename, "login") == 0) {
			if (cgi_auth_status() == auth_status_ok) {
				return page_access_none;
			}
			return page_access_ro;
		}
	}

	// Role-based permission checks

	log_debug("auth", "Checking group permissions for page '%s' for role '%s'", pagename, role);

	return page_access_group_permissions(page_get(pagename), role);
}

// Provide a password hash to encrypt passwords
const char *auth_get_password_hash(const char *username, const char *password)
{
	/* crypt the password */
	return crypt(password, "$1$");
}

// vim:se ts=4:
