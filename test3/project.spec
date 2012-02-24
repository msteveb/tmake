# vim:set syntax=tcl:

define? UWEB /usr/local/uweb
define? DESTDIR _install
define? CONFIG_DIR $DESTDIR/etc/config

Load $UWEB/lib/build.conf
define? UWEB_LDLIBS -luweb
define THEMES $UWEB/themes

define? PARSE_APP $UWEB/bin/parse-app
define? PARSE_PAGE $UWEB/bin/parse-page
define? PARSE_LAYOUT $UWEB/bin/parse-layout

LinkFlags -L$UWEB/lib
UseSystemLibs -luweb -ljim $UWEB_LDLIBS
CFlags -I$UWEB/include

# This is for uweb-1.3.x
#if {[regexp -line {^LDFLAGS := (.*)$} [readfile $UWEB/lib/build-default.mak] -> libs]} {
#	UseSystemLibs $libs
#}

# Given glob patterns matching .page, .app and .menus files, 
# defines rules to generate sources and returns a list of the sources
# generated
#
# Usage: Executable webapp main.c ... [CgiSources *.page *.app *.menus]
#
proc CgiSources {args} {
	set srcs {}
	set args [join $args]
	foreach i [Glob --all $args] {
		switch -glob -- $i {
			*.page {
				Generate $i.c {} $i {
					run $PARSE_PAGE $inputs -o $target
				}
			}
			*.app {
				# Note that we add $allpages here to ensure that
				# all the app.c file is regenerated if any page files are added
				# or removed
				Generate $i.c {} $i {
					# $allpages
					run $PARSE_APP $inputs -o $target
				} -vars allpages [Glob *.page]
			}
			*.menus {
				Generate $i.c {} $i {
					run $PARSE_LAYOUT $inputs -o $target
				}
			}
			default {
				error "Don't know what to do with $i"
			}
		}
		lappend srcs $i.c
	}
	return $srcs
}
