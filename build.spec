Phony all -add -do {
	foreach dir {test1 test2 test3 test4} {
		run make -C $dir
		#run tmake -C$dir
	}
}
Phony clean -replace -do {
	foreach dir {test1 test2 test3 test4} {
		run make -C $dir $target
		#run tmake -C$dir clean
	}
}
