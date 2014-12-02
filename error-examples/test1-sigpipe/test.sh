#!/bin/bash

${TMAKE:-tmake} | head >got.txt || RC=1
if [ ${PIPESTATUS[0]} != 1 ]; then
	RC=1
fi
diff expected.txt got.txt || RC=1
rm got.txt
rm -rf objdir

exit $RC
