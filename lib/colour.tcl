set tmake(colout) 0
set tmake(colerr) 0

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
	lred "\x1b\[31;1m"
	lgreen "\x1b\[32;1m"
	lyellow "\x1b\[33;1m"
	lblue "\x1b\[34;1m"
	lpurple "\x1b\[35;1m"
	lcyan "\x1b\[36;1m"
	white "\x1b\[37;1m"
}

proc init-colour {} {
	global tmake

	if {[getenv NOCOLOR ""] eq "" && [getenv TERM ""] ni {dumb emacs cygwin}} {
		set tmake(colout) [isatty? stdout]
		set tmake(colerr) [isatty? stderr]
	}
}

proc colstr {colour string} {
	return [dict get $::tmake(ansicodes) $colour]$string[dict get $::tmake(ansicodes) none]
}

proc colout {colour string} {
	if {$::tmake(colout)} {
		return [colstr $colour $string]
	}
	return $string
}

proc colerr {colour string} {
	if {$::tmake(colerr)} {
		return [colstr $colour $string]
	}
	return $string
}
