#!/bin/sh

# Give a packagename (minus the .tar.gz) as $1, untars, configures, installs and uninstalls the package
# If everything works and there is nothing left over, declare success

set -e
mkdir -p distcheckdir
echo Unpacking $1.tar.gz
gzcat $1.tar.gz | tar -C distcheckdir -xf -
(
	set -e
	cd distcheckdir/$1
	echo "Configuring..."
	./configure >config.out
	echo "Building..."
	make DESTDIR=_install install
	echo "Uninstalling..."
	make DESTDIR=_install uninstall
	if test -d _install; then
		echo 1>&2 "Uninstall did not remove all files"
		exit 1
	fi
)
rm -rf distcheckdir
echo "Looks OK"
