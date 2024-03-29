# vim:set syntax=tcl:

# The rest of the build description is only used if configured
ifconfig CONFIGURED

IncludePaths include

# Pull in some autosetup config
CFlags -DHAVE_AUTOCONFIG_H $EXTRA_CFLAGS
LinkFlags $EXTRA_LDFLAGS
UseSystemLibs $LIBS

HostExecutable translate translate.c
HostExecutable makeheaders makeheaders.c
HostExecutable mkindex mkindex.c
HostExecutable mkversion mkversion.c

set src {
	add allrepo attach bag bisect blob branch browse captcha cgi
	checkin checkout clearsign clone comformat configure content db
	delta deltacmd descendants diff diffcmd doc encode event export
	file finfo glob graph gzip http http_socket http_transport import
	info leaf login manifest md5 merge merge3 name path pivot
	popen pqueue printf rebuild report rss schema search setup sha1
	shun skins sqlcmd stash stat style sync tag tar th_main timeline
	tkt tktsetup undo update url user verify vfile wiki wikiformat
	winhttp xfer zip http_ssl
}

Generate page_index.h mkindex [suffix .c $src] {
	run $script $inputs >$target
}

# makeheaders is messy because it tries to do so much.
# a simpler approach would be to have a tool which generated a single header from
# a single source file.

set gen_headers {}
set headers {}
set header_deps {}
foreach b [concat $src main] {
	Generate ${b}_.c translate $b.c {
		run $script $inputs >$target
	}
	lappend gen_headers [file-build ${b}_.c]:[file-build include/$b.h]
	lappend headers include/$b.h
	lappend header_deps ${b}_.c
}

lappend gen_headers sqlite3.h th.h [file-build include/VERSION.h]
lappend header_deps sqlite3.h th.h include/VERSION.h

Generate $headers makeheaders $header_deps {
	file mkdir include
	run $script $gen_headers
} -vars gen_headers $gen_headers -msg {note GenerateHeaders}

# Special flags on some objects
ObjectCFlags sqlite3.c -DSQLITE_OMIT_LOAD_EXTENSION=1 -DSQLITE_THREADSAFE=0 -DSQLITE_DEFAULT_FILE_FORMAT=4
ObjectCFlags sqlite3.c -DSQLITE_ENABLE_STAT2 -Dlocaltime=fossil_localtime -DSQLITE_ENABLE_LOCKING_STYLE=0

ObjectCFlags shell.c -Dmain=sqlite3_shell -DSQLITE_OMIT_LOAD_EXTENSION=1

Lib fossil [suffix _.c $src] th.c th_lang.c sqlite3.c shell.c

Executable fossil main_.c

#Executable winhttp winhttp.c

Generate include/VERSION.h mkversion {manifest.uuid manifest VERSION} {
	run $script $inputs >$target
}
