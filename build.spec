AutoSubDirs off

#target clean -replace -phony
foreach dir [Glob --dirs test?] {
	Phony all-$dir -do "run tmake -C $dir"
	Depends all all-$dir
	Phony clean-$dir -nofail -do "run tmake -C $dir clean"
	Depends clean clean-$dir
	Phony distclean-$dir -nofail -do "run tmake -C $dir distclean"
	Depends distclean distclean-$dir
}
