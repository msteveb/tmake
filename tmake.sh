#!/bin/sh

# Look for autosetup/tmake in the current dir and
# each parent directory until found, and execute it
# If not found, output a diagnostic message

# Install as 'tmake' somewhere in the PATH

here=$(pwd)
while [ "$here" != "/" ]; do
	TMAKE=$here/autosetup/tmake
	if [ -x "$TMAKE" ]; then
		exec "$TMAKE" "$@"
	fi
	here=$(dirname "$here")
done

echo 1>&2 "Could not find autosetup/tmake in any parent directory"
exit 1
