if 0 {
proc HostExecutable {target args} {
	target [make-local $target] -inputs {*}[make-local {*}$args] -do {
		run $CC_FOR_BUILD -o $target $inputs
	}
	Publish bin $target
	Clean $target
}
}
