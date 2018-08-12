# The png16 library is provided by the libpng external build
UseLibs png16
UseSystemLibs -lz

# This is our test program
Executable pngtest pngtest.c

# Run the test
Test pngtest libpng/pngtest.png
Clean --source pngout.png

# ------------------------------------------------
# Fetching the git repository
# ------------------------------------------------

# For simplicity we want to be able to run 'tmake fetch' to fetch the subrepo
# We don't want distclean to remove the repo, but it will remove the libpng/.fetched stamp.
# So create a copy of .fetched in the source repo that will be loaded if libpng is already fetched.
Load libpng/.fetched

ifconfig !LIBPNG_FETCHED {
	Depends libpng/.fetched -nofork -msg {note Clone libpng} -do {
		# This is fetched in the source directory
		exec git clone git://git.code.sf.net/p/libpng/code libpng 2>@stderr
		writefile $target "define LIBPNG_FETCHED\n"
		# note the 'cd' below
		cd libpng
		exec ./autogen.sh
		# By writing this to the source directory too, it will still work
		# after distclean. 
		writefile .fetched "define LIBPNG_FETCHED\n"
	}
}
Phony fetch libpng/.fetched
DistClean libpng/.fetched

ifconfig LIBPNG_FETCHED

# We don't want to include build.spec in the libpng directory
# so we create a "virtual" build.spec that acts as though it exists there
VirtualSubDir libpng {
	ExternalBuild {
		configure_targets {Makefile config.h}
		configure_opts {--enable-static --disable-shared}
		build_targets {pngfix pngunknown pngimage libpng16-config libpng16.pc pnglibconf.h}
		lib_targets {png16 .libs/libpng16.a}
	}

	PublishIncludes png.h pngconf.h pngdebug.h pnginfo.h pngstruct.h pnglibconf.h
}
