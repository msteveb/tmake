Phony all -do {
	foreach i [range 1000] {
		puts hello
		stdout flush
	}
}
