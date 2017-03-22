define AR ar
define CC {cc -Qunused-arguments}
define CC_FOR_BUILD cc
define CFLAGS {-g -O2}
define CPP {cc -E}
define CPPFLAGS {}
define CXX c++
define CXXFLAGS {-g -O2}
define EXEEXT {}
define LDFLAGS {}
define LD_LIBRARY_PATH DYLD_LIBRARY_PATH
define LIBS {}
define LINKFLAGS {}
define RANLIB ranlib
define SHOBJ_CFLAGS {-dynamic -fno-common}
define SHOBJ_LDFLAGS {-bundle -undefined dynamic_lookup}
define SHOBJ_LDFLAGS_R -bundle
define SH_CFLAGS -dynamic
define SH_LDFLAGS -dynamiclib
define SH_LINKFLAGS {}
define SH_SOEXT .dylib
define SH_SOEXTVER .%s.dylib
define SH_SOPREFIX -Wl,-install_name,
define STRIPLIBFLAGS -x

