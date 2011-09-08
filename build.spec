AutoSubDirs off

#target clean -replace -phony
foreach dir {test1 test2 test3 test4 test5 test6} {
	Phony all-$dir -do "run tmake -C $dir"
	Depends all all-$dir
	Phony clean-$dir -nofail -do "run tmake -C $dir clean"
	Depends clean clean-$dir
	Phony distclean-$dir -nofail -do "run tmake -C $dir distclean"
	Depends distclean distclean-$dir
}
