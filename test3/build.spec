# vim:set syntax=tcl:

define? UWEB /usr/local/uweb
define? DESTDIR _install
define? CONFIG_DIR $DESTDIR/etc/config

define THEMES $UWEB/themes

LinkFlags -L$UWEB/lib
UseSystemLibs -luweb -ltcl6

CFlags -Wall -g -Os -I. -I$UWEB/include

set srcs {}

foreach i [glob *.page *.app *.menus] {
	Generate $i.c {} $i {
		switch -glob -- $inputs {
			*.page {
				run $UWEB/bin/parse-page $inputs -o $target
			}
			*.app {
				run $UWEB/bin/parse-app $inputs -o $target
			}
			*.menus {
				run $UWEB/bin/parse-layout $inputs -o $target
			}
		}
	}
	define-append srcs $i.c
}

Executable --install=/home/httpd/cgi-bin web auth.c customstorage.c init.c main.c tclcustom.c $srcs

Install /home/httpd/css *.css $THEMES/basic.css=basic1.css
Install /home/httpd/javascript *.js
Install /home/httpd/img img/*.{png,gif,ico,jp*} $THEMES/black_icons/*checked.png
Install /lib/tcl6 $UWEB/lib/tcl6/*.tcl *.tcl

Phony run install -rules {
	file mkdir $CONFIG_DIR
	set ::env(UWEB_CONFIG_DIR) [file join [pwd] $CONFIG_DIR]
	set ::env(TCLLIBPATH) [file join [pwd] $DESTDIR/lib/tcl6]

	puts "Point your browser to http://localhost:8000/"
	run $DESTDIR/home/httpd/cgi-bin/web server 8000
}

Phony server run
