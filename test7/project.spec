proc glob-src {args} {
	set result {}
	foreach pattern $args {
		foreach {i j} [expand-wildcards $pattern] {
			lappend result $j
		}
	}
	return $result
}
