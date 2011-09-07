AutoSubDirs off

foreach dir {test1 test2 test3} {
	Phony all -add -do "run tmake -C$dir"
	Phony clean -add -nofail -do "run tmake -C$dir clean"
	Phony distclean -add -nofail -do "run tmake -C$dir distclean"
}
