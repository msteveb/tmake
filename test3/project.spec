# vim:set syntax=tcl:

# Given glob patterns matching .page, .app and .menus files, 
# defines rules to generate sources and returns a list of the sources
# generated
#
# Usage: Executable webapp main.c ... [CgiSources *.page *.app *.menus]
#
proc CgiSources {args} {
	set srcs {}
	foreach i [glob {*}[make-local {*}$args]] {
		set i [file tail $i]
		switch -glob -- $i {
			*.page {
				Generate $i.c {} $i {
					run $UWEB/bin/parse-page $inputs -o $target
				}
			}
			*.app {
				Generate $i.c {} $i {
					# Ensure rebuilt if the list of files changes
					# [lsort [glob *.page]]
					run $UWEB/bin/parse-app $inputs -o $target
				}
			}
			*.menus {
				Generate $i.c {} $i {
					run $UWEB/bin/parse-layout $inputs -o $target
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
