IncludePaths .

PublishIncludes x.h
Lib --publish x x.c

Generate xgen.h <bin>gen xgen.h.in {
	run $script <$inputs >$target
}
