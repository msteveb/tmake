#include <cgitcl.h>

int cgi_tcl_callback(const char *script, const char *filename, int line, page_t *page, elem_t *elem)
{
	return cgi_tcl_std_callback(script, filename, line, page, elem);
}
