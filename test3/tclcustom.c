#include <cgitcl.h>

/* This is the standard uWeb-Jim Tcl connector.
 * If you don't want to use Tcl, you can remove this source file which
 * will avoid linking with Jim Tcl library.
 */
int cgi_tcl_callback(const char *script, const char *filename, int line, page_t *page, elem_t *elem)
{
	return cgi_tcl_std_callback(script, filename, line, page, elem);
}

void cgi_tcl_free(void)
{
	cgi_tcl_free_interp();
}
