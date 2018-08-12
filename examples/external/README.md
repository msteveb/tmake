This project provides an example of using ExternalBuild

The idea is that some external project (in this case libpng) already
provides it's own build system. We don't want to rely on a prebuilt
package (e.g. via pkg-config), but instead want to build, link and install
build products from that external project.

Here we build and link pngtest.c against the libpng static library
(shared libraries not yet supported)

We also provide a phony target 'fetch' that fetches the source
code for libpng into our tree, for example, if you don't want to
use git submodules.
