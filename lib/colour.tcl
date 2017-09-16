# Copyright (c) 2012 WorkWare Systems http://www.workware.net.au/
# All rights reserved
#
# @synopsis:
#
# Provide colourised output to ANSI-compatible terminals
#
# Colourised output will not be used if:- $NOCOLOR is set in the environment,
# $TERM is one of dumb, emacs or cygwin, or if the channel (stdout, stderr)
# is not a tty.
#
# Note that tmake allows colour to be forced on with --col and forced off with --nocol
#
# Known colours are: none black red green yellow blue purple cyan normal gray grey lred
# lgreen lyellow lblue lpurple lcyan white

# Should colourised output be used to stdout and stderr?
set tmake(colout) 0
set tmake(colerr) 0

# These are the ANSI escape sequences
set tmake(ansicodes) {
	none "\x1b\[0m"
	black "\x1b\[30m"
	red "\x1b\[31m"
	green "\x1b\[32m"
	yellow "\x1b\[33m"
	blue "\x1b\[34m"
	purple "\x1b\[35m"
	cyan "\x1b\[36m"
	normal "\x1b\[37m"
	grey "\x1b\[30;1m"
	gray "\x1b\[30;1m"
	lred "\x1b\[31;1m"
	lgreen "\x1b\[32;1m"
	lyellow "\x1b\[33;1m"
	lblue "\x1b\[34;1m"
	lpurple "\x1b\[35;1m"
	lcyan "\x1b\[36;1m"
	white "\x1b\[37;1m"
}

# Colour aliases
set tmake(colalias) {}

proc init-colour {} {
	global tmake

	if {[getenv NOCOLOR ""] eq "" && [getenv TERM ""] ni {dumb emacs cygwin}} {
		set tmake(colout) [isatty? stdout]
		set tmake(colerr) [isatty? stderr]
	}
}

# @colstr colour string
#
# Return a value that will output the string to an ANSI terminal with the given colour, or alias.
proc colstr {colour string} {
	return [colget $colour]$string[colget none]
}

# @colout colour string
#
# Return a coloured message destined for stdout. The message
# will only be coloured if colour support is enabled for stdout.
proc colout {colour string} {
	if {$::tmake(colout)} {
		return [colstr $colour $string]
	}
	return $string
}

# @colerr colour string
#
# Return a coloured message destined for stderr. The message
# will only be coloured if colour support is enabled for stderr.
proc colerr {colour string} {
	if {$::tmake(colerr)} {
		return [colstr $colour $string]
	}
	return $string
}

# @colalias name colour
#
# Set or replace a name that will alias to the given colour
# Note that aliases may only refer to base colours, not other aliases.
#
proc colalias {name colour} {
	if {[dict exists $::tmake(ansicodes) $colour]} {
		dict set ::tmake(colalias) $name $colour
	} else {
		return -code error "Unknown colour, $colour, specified for alias"
	}
}

# @colget name
#
# Returns the ansi code for the given alias or base colour.
# The name must exist as an alias or base colour.
proc colget {name} {
	if {[dict exists $::tmake(colalias) $name]} {
		set name [dict get $::tmake(colalias) $name]
	}
	dict get $::tmake(ansicodes) $name
}
