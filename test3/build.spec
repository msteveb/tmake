define? UWEB /usr/local/uweb

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

if 0 {
install: all install_dirs install_basic_theme install_tcl install_help
	install $(PROGRAM) $(DESTDIR)/home/httpd/cgi-bin/$(PROGRAM)
	install *.css $(DESTDIR)/home/httpd/css
	install $(IMGS) $(DESTDIR)/home/httpd/img
	install *.js $(DESTDIR)/home/httpd/javascript
	install *.tcl $(DESTDIR)/lib/tcl6

install_dirs:
	install -d $(DESTDIR)/home/httpd/cgi-bin
	install -d $(DESTDIR)/home/httpd/css
	install -d $(DESTDIR)/home/httpd/img
	install -d $(DESTDIR)/home/httpd/javascript
	install -d $(DESTDIR)/bin

# May need to install any local tcl packages here too - to $(DESTDIR)/lib/tcl6
install_tcl:
	install -d $(DESTDIR)/lib/tcl6
	install $(UWEB)/lib/tcl6/*.tcl $(DESTDIR)/lib/tcl6

install_help: install_dirs
	install $(COMMON)/help.png $(DESTDIR)/home/httpd/img

install_basic_theme: install_dirs
	install $(THEMES)/basic.css $(DESTDIR)/home/httpd/css/basic1.css
	install $(THEMES)/black_icons/*.png $(DESTDIR)/home/httpd/img

server run:
	mkdir -p $(CONFIG_DIR)
	UWEB_CONFIG_DIR=$(CONFIG_DIR) TCLLIBPATH=$(DESTDIR)/lib/tcl6 $(DESTDIR)/home/httpd/cgi-bin/$(PROGRAM) server 8000

clean:
	rm -f *.o lib*.a *.page.c *.app.c *.menus.c $(PROGRAM)
	rm -rf _install
}
