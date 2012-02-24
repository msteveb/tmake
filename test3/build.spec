CFlags -Wall -Os

Executable --install=/home/httpd/cgi-bin web auth.c customstorage.c init.c main.c tclcustom.c \
	[CgiSources *.page *.app *.menus]

Install /home/httpd/css *.css basic1.css=$THEMES/basic.css
Install /home/httpd/javascript *.js
Install /home/httpd/img img/*.{png,gif,cio,jp*} $THEMES/black_icons/*checked.png
Install /lib/jim $UWEB/lib/jim/*.tcl *.tcl

Phony run install -do {
	file mkdir $CONFIG_DIR
	set ::env(UWEB_CONFIG_DIR) [file join [pwd] $CONFIG_DIR]
	set ::env(TCLLIBPATH) [file join [pwd] $DESTDIR/lib/jim]

	puts "Point your browser to http://localhost:8000/"
	run $DESTDIR/home/httpd/cgi-bin/web server 8000
}
