# Warning: Automatically created by automf v0.6.4 -- do not edit

.PHONY: ALL TEST CLEAN INSTALL all test install uninstall clean distclean jam_clean jam_distclean
.DELETE_ON_ERROR:
.EXPORT_ALL_VARIABLES:
.NOTPARALLEL:

ifdef V
ifeq ("$(origin V)", "command line") 
BUILD_VERBOSE := $(V)
endif
endif

# Use make V=1 to enable verbose mode
# Use make J=... to explicitly set jam options, but only on the command line
ifneq ("$(origin J)", "command line") 
J :=
endif

ifeq ($(BUILD_VERBOSE),1)
Q :=
ECHO := @:
J += -dx
else
Q := @
ECHO := @echo
endif

ifneq ($(findstring clean,$(MAKECMDGOALS)),)
CLEANING := 1
endif
ifneq ($(findstring CLEAN,$(MAKECMDGOALS)),)
CLEANING := 1
endif
ifneq ($(findstring n,$(MAKEFLAGS)),)
J += -n
endif

ifndef TOPDIR
TOPDIR := 
TOP :=
AUTOMF_CLEAN = $(AUTOMF) --clean
projclean = $(PROJCLEAN)
projdistclean = $(PROJCLEAN) $(PROJDISTCLEAN)
endif

TCLLIBPATH = $(TOPDIR)lib

JAMFILE := $(TOPDIR)Jamfile

# Default target
_all: all

# Load project-specific definitions
-include $(TOPDIR)project.mak

# Make sure PROJDEPS are up-to-date before running jam
all install uninstall test: $(PROJDEPS) $(JAMFILE)
	$(Q)+jam $(J) "$(grist)$@"

# Allow arbitrary jam targets to be built as <target>_jam
%_jam: $(PROJDEPS) $(JAMFILE)
	$(Q)+jam $(J) "$(@:_jam=)"

clean: jam_clean $(projclean)

jam_clean:
	$(Q)+if [ -f $(JAMFILE) ]; then jam $(J) "$(grist)clean"; fi

distclean: jam_distclean $(projdistclean)

jam_distclean:
	$(Q)+if [ -f $(JAMFILE) ]; then jam $(J) "$(grist)distclean"; fi
	$(AUTOMF_CLEAN)

# These are global targets
ALL: $(PROJDEPS) $(JAMFILE)
	$(Q)+jam $(J) all

TEST: $(PROJDEPS) $(JAMFILE)
	$(Q)+jam $(J) test

INSTALL: $(PROJDEPS) $(JAMFILE)
	$(Q)+jam $(J) install

CLEAN: $(PROJCLEAN)
	$(Q)+if [ -f $(JAMFILE) ]; then jam $(J) clean; fi

DISTCLEAN: $(PROJCLEAN) $(PROJDISTCLEAN)
	$(Q)+if [ -f $(JAMFILE) ]; then jam $(J) distclean; fi
	$(AUTOMF) --clean


AUTOMF := automf 

.PRECIOUS: $(TOPDIR)GNUmakefile
$(JAMFILE) $(TOPDIR)GNUmakefile: $(TOPDIR)project.spec $(TOPDIR)build.spec 
	$(AUTOMF)
