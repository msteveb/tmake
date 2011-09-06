# vim:set syntax=tcl:

# load autosetup settings
Load settings.conf
DistClean settings.conf autoconfig.h
Depends settings.conf -do {
	user-error "settings.conf does not exist"
}

IncludePaths include

CFlags -DHAVE_AUTOCONFIG_H
UseSystemLibs $LIBS

# XXX: Simple host executable for now
proc HostExecutable {target args} {
	target [make-local $target] -inputs {*}[make-local {*}$args] -do {
		run $CC_FOR_BUILD -o $target $inputs
	}
	Clean $target
}

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

set gen_headers {}
set headers {}
set header_deps {}
foreach b "$src main" {
	Generate ${b}_.c translate $b.c {
		run $script $inputs >$target
	}
	lappend gen_headers ${b}_.c:include/$b.h
	lappend headers include/$b.h
	lappend header_deps ${b}_.c
}

# Note: make-local-src is needed here because these filenames are not passed as inputs or dependencies,
#       and nor are they targets, so tmake doesn't know that they are in the source tree.
lappend gen_headers {*}[make-local-src sqlite3.h th.h]
lappend gen_headers include/VERSION.h
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
