# Avoid built-in rules and variables
MAKEFLAGS += rR

all clean distclean:
	+@jimsh ../tmake $(MFLAGS) $@

%:
	+@jimsh ../tmake $(MFLAGS) $(MAKECMDGOALS)

.EXPORT_ALL_VARIABLES:

