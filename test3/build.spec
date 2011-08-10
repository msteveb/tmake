define? UWEB /usr/local/uweb
define? DESTDIR _install
define? CONFIG_DIR $DESTDIR/etc/config

define COMMON $UWEB/common
define THEMES $UWEB/themes

LinkFlags -L$UWEB/lib 
UseSystemLibs -luweb -ltcl6

CFlags -Wall -g -Os -I. -I$UWEB/include

#IMGS = $(filter-out img/CVS img/%~, $(wildcard img/*))

# Include some common modules too
# Note that we use VPATH to find these, but they can be
# copied to the local directory and modified if required.

#OBJS = $(PAGES:.page=.page.o) $(APP:.app=.app.o) $(LAYOUT:.menus=.menus.o) $(SRCS:.c=.o)
#PATH := $(PATH):$(UWEB)/bin
#CONFIG_DIR ?= $(DESTDIR)/etc/config
#PROGRAM := web

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

Executable web auth.c customstorage.c init.c main.c tclcustom.c $srcs

Install --bin /home/httpd/cgi-bin web
Install /home/httpd/css [glob *.css] $THEMES/basic.css=basic1.css
Install /home/httpd/javascript [glob *.js]
Install /home/httpd/img [glob -nocomplain img/*.{png,gif,ico,jp*}] [glob $THEMES/black_icons/*checked.png]
Install /lib/tcl6 [glob $UWEB/lib/tcl6/*.tcl *.tcl]

target run -depends install -rules {
	file mkdir $CONFIG_DIR
	set env(UWEB_CONFIG_DIR) $CONFIG_DIR
	set env(TCLLIBPATH) $DESTDIR/lib/tcl6 
	puts "Point your browser to http://localhost:8000/"
	run $DESTDIR/home/httpd/cgi-bin/web server 8000
}

Alias server run
