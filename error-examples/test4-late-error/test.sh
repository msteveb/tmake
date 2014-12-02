#!/bin/sh

RC=0
TMAKE_ERROR=late ${TMAKE:-tmake} >out.txt 2>err.txt && RC=1
diff -u out.exp out.txt || RC=1
diff -u err.exp err.txt || RC=1
if [ "$1" = "init" ]; then
	mv out.txt out.exp; mv err.txt err.exp
else
	rm out.txt err.txt
fi
rm -rf objdir

exit $RC
