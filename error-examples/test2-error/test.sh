#!/bin/bash

RC=0
${TMAKE:-tmake} >out.txt 2>err.txt && RC=1
diff -u out.exp out.txt || RC=1
diff -u err.exp err.txt || RC=1
rm out.txt err.txt
rm -rf objdir

exit $RC
