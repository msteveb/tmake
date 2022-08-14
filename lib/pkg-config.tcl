# Copyright (c) 2016 WorkWare Systems http://www.workware.net.au/
# All rights reserved

# @synopsis:
#
# Module which provides simple pkg-config support

# @pkg-config modulename
#
# If the given pkg-config module was detected with autosetup,
# add the required compiler/linker flags and libraries.
# Returns 1 if found/added, or 0 otherwise.
#
# Typicaly usage is as follows:
#
# In auto.def:
#
## use pkg-config
## if {[pkg-config pango >= 1.30.0]} {
##   msg-result "Enabling pango"
## }
#
# In build.spec:
#
## use pkg-config
## if {[pkg-config pango]} {
##   lappend sources pango-integration.c
## }
#
proc pkg-config {name} {
	# This is the same as feature-define-name from autosetup
	set prefix [string toupper pkg_[regsub -all {[^a-zA-Z0-9]} [regsub -all {[*]} $name p] _]]
	set rc 0
	ifconfig HAVE_$prefix {
		UseSystemLibs {*}[get-define ${prefix}_LIBS]
		CFlags {*}[get-define ${prefix}_CFLAGS]
		C++Flags {*}[get-define ${prefix}_CFLAGS]
		LinkFlags {*}[get-define ${prefix}_LDFLAGS]
		set rc 1
	}
	return $rc
}
