#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <cgitypes.h>
#include <cgitcl.h>
#include <jim.h>
#include <stringlist.h>

// Validation of an email address (very basic).
static const char *check_email(const char *typeflags, const char *value)
{
	if (!value || !(*value)) {
		return "Must not be blank";
	}

	if (*value == '@' || strchr(value, '@') == 0) {
		return "Must be a valid email address";
	}

	return NULL;
}

static type_t type_email = {
	.type = "email",
	.check = check_email,
};

// Validation check for an individual IP address.
static const char *check_ipaddr(const char *value)
{
	static char buf[128];
	struct in_addr in;

	if (inet_aton(value, &in) == 0) {
		snprintf(buf, sizeof(buf), "%s is not a valid IP address", value);
		return buf;
	}

	return NULL;
}

// Local function to do work of validation of list of IP addresses.
static const char *check_iplist(stringlist *sl, const char *value)
{
	if (!sl || sl_count(sl) < 1) {
		return "Need at least one IP address in list";
	}

	const char *pt;
	for (pt = sl_first(sl); pt; pt = sl_next(sl, pt)) {
		const char *result = check_ipaddr(pt);
		if (result) {
			return result;
		}
	}

	return NULL;
}

// Validation of list of IP addresses.
static const char *check_ipaddrlist(const char *typeflags, const char *value)
{
	// Split value into list of individual IP addrs
	stringlist *sl = sl_split(value, " ");
	const char *result = check_iplist(sl, value);
	sl_free(sl);
	return result;
}

static type_t type_ipaddrlist = {
	.type = "ipaddrlist",
	.check = check_ipaddrlist,
};

void init_app(void)
{
	type_add(&type_email);
	type_add(&type_ipaddrlist);

	cgi_tcl_eval("package require common", 1);
}

// vim: se ts=4:
