Phony all -do {
	foreach i [range 1000] {
		puts hello
		flush stdout
	}
}
