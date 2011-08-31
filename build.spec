AutoSubDirs off

Phony all -add -do {
	foreach dir {test1 test2 test3 test4} {
		run tmake -C$dir
	}
}
Phony clean -replace -do {
	foreach dir {test1 test2 test3 test4} {
		catch {run tmake -C$dir $target}
	}
}
Phony distclean -replace -do {
	foreach dir {test1 test2 test3 test4} {
		run tmake -C$dir $target
	}
}
