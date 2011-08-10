appname "EtherMux E620"
defaultpage overview
authpage -app login

stylesheet /css/basic1.css
stylesheet /css/web1.css
javascript /javascript/jscript1.js
icon /img/em-logo.ico
icon rel=apple-touch-icon /img/em-touch-logo.png

# Add custom init for this app
init init_app

toolbar tcl

storage custom

pages {
	*.page
}

# vim:se ts=4:
