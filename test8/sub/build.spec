IncludePaths .

PublishIncludes x.h
Lib --publish x x.c

Generate xgen.h gen xgen.h.in {
	run $script <$inputs >$target
}
