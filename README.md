Overview of tmake
-----------------
Currently implementation is a usable proof-of-concept.
It has perfectly acceptable performance for small projects (~1000 files),
but slows down beyond that. It also has no support for parallel builds.

What it does have:
- Build descriptions are succinct and declarative
- A real language for build descriptions (Tcl), with simple conditional syntax
- Rules can create multiple files
- Two-stage reparsing to allow build configuration to be generated and reloaded
  (e.g. via configure or kconfig)
- Cache of built targets allows for:
  - Cleaning orphan targets
  - Rebuilding if build commands change
  - Rebuilding if the target is to be built by a different rule
  - A file is "up-to-date" if it rule runs even if the file didn't change (virtual mtime)
- Good support for "generators" which generate 
- Dynamic dependency support, including caching dependencies and support for generated files
- Excellent debugging facilities to identify exactly what is occuring and why
- 'tmake --find' to find specify rules
- Support for out-of-tree builds
- Non-recursive
- Automatic creation of directories as required
- Common operations (mkdir, rm) can be done without forking a process
- Bootstraps with no external tools, just a C compiler
- Add additional dependencies, bound vars, etc. to existing rules
- Generates stub Makefiles to easily allow 'make' from any subdirectory

Essentially almost everything listed here: http://www.conifersystems.com/whitepapers/gnu-make/
is addressed, except performance.

Simple things are simple
------------------------

# Set CFLAGS for all subsequent sources
CFlags -DPOLARSSLTEST

# Build a library from sources
Lib polarssl {
     aes.c arc4.c asn1parse.c asn1write.c base64.c bignum.c camellia.c
     certs.c cipher.c cipher_wrap.c ctr_drbg.c debug.c des.c dhm.c
     entropy.c entropy_poll.c error.c havege.c md.c md_wrap.c md2.c
     md4.c md5.c net.c padlock.c pem.c pkcs11.c rsa.c sha1.c sha2.c
     sha4.c ssl_cli.c ssl_srv.c ssl_tls.c timing.c version.c
     x509parse.c x509write.c xtea.c
}

# Automatically links against polarssl
Executable polarssl main.c

High Level vs Low Level Rules
-----------------------------
The core tmake essentially has a single command to create a rule, target.
While it would be possible to create a build description purely with the 'target' command,
tmake is designed to layer a higher-level set of build commands.

The default rulebase includes such a set of high level rules, such as Executable,
ArchiveLib, SharedObject, Phony, Install and more.

The default rulebase may be extended or replaced, or rules tweaked
with the low level 'target' if required.

Differences with make
---------------------
- Differenentiates between rule 'inputs' and 'dependencies'
- Allows binding of values to variables during the definition phase which are
  then available to the command(s) at run time.
- Commands are Tcl scripts, which means that many operations do not require a fork/exec
- The 'run' built-in runs external commands
- Commands used to build a target a cached so that 
- Automatic directory creation

Documentation for the 'target' command
--------------------------------------
Explain the '-key values...' structure of arguments to 'target'.

-phony
	Marks the target as phony. A phony target is considered to always need building
	and any file with the same name is ignored. Typical phony targets are: all, clean, test, install

-nofail
	Failure of the '-do' commands for the rule is ignored.

-replace
	First discards any previous rule for the target.

-add
	Normally only one rule for a target may contain -do. With -add, -do commands
	may be added to an existing rule.

-chdir
	Normally all commands are run from the top level build directory.
	If -chdir is given, commands for this target are run from the local build subdirectory
	instead. This is most often used for unit tests or generators which make assumptions
	about the current directory. It should be avoided where possible.

-nocache
	Do not cache this target. Note that the 'Install' command from rulebase.default
	uses -nocache for performance reasons since install targets are never used
	as dependencies.

-inputs targets
	List of files/targets which are used by the -do command to create the target.
	These targets are available to the -do command as $inputs

-depends targets
	List of files/targets upon which this target depends.
	These targets are available to the -do command as $targets
	Note that -inputs are automatically added to -depends

-clean filenames
	List of files/targets which should be deleted after the -do commands run.
	Used to clean up temporary files

-msg command
	Tcl script to run when the rule is invoked to build the target.
	Should be succinct to avoid excess output in the normal case.
	For example, the default object rule for .c files uses:

	  -msg {note Cc $target}

-onerror command
	Tcl script to run if the command fails. Allows for cleanup, e.g. of
	temporary files.

-do command
	Tcl script to run when the target needs to be built.
	Unless the target is phony, the -do command *must* create the given target(s).
	The standard variables are set for the rule ($inputs, $target, etc.)

-dyndep command-prefix
	Tcl command prefix invoked to extract dynamic dependencies from each of the dependencies.
	Returns a list of dependencies. See header-scan-regexp-recursive and ObjectRule.c
	in rulebase.default for an example.

-vars name value ...
	Binds the names to the values for the rule.
	Before invoking Tcl commands associated with -do, -msg, -onerror and -dyndep, variables (defines) are
	created/set according to any bound variables. For example, in the following rule, $C_FLAGS
	and $INCPATHS are set to the given values before the -dyndep and -do scripts are run.
	Compare this with $CCACHE, $CC and $CFLAGS which are global variables (defines) which are the
	same for all rules.

	Note that if a -var is specified multiple times (possibly in multiple rules), the values accumulate
	(with a space separator). Condsider the rule created by:
	
	  Objects auth.app.c

		authapp/auth.app.o: authapp/auth.app.c
		dyndep=header-scan-regexp-recursive $INCPATHS "" $HDRPATTERN
		local=authapp
		  var C_FLAGS=-Wall -g -Os -fstrict-aliasing -Werror -D_GNU_SOURCE -std=gnu99 -Iinclude -Ipublish/include -Iauthapp
		  var INCPATHS=include publish/include authapp
				run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

	Let's add an include path to this rule:

	  Depends auth.app.o -vars INCPATHS axtls

	Now the new rule is:

		authapp/auth.app.o: authapp/auth.app.c
		dyndep=header-scan-regexp-recursive $INCPATHS "" $HDRPATTERN
		local=authapp
		  var C_FLAGS=-Wall -g -Os -fstrict-aliasing -Werror -D_GNU_SOURCE -std=gnu99 -Iinclude -Ipublish/include -Iauthapp
		  var INCPATHS=include publish/include authapp axtls
				run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

-getvars name ...
	Similar to -vars, except that the value of the variable is taken from current value
	of the global variable (define)

Variables available during parsing
----------------------------------

Variables available to commands
-------------------------------
In the -do clause of a command, the following variables are defined.

$target  - The target(s) of the rule
$inputs  - Any files mentioned with -inputs
$depends - Any files mentioned with -depends, plus any mentioned with -inputs
$local   - The (relative) directory associated with the rule

In addition, any variables defined with 'define' (including variants) are available.

And any variables bound with -vars or -getvars (these take precedence over global 'define's)

project.spec, build.spec, rulebase.spec, rulebase.default, autosetup/
---------------------------------------------------------------------
- reparsing after project.spec
- subdirvars
- BuildSpecProlog/BuildSpecEpilog

Variables/Defines
-----------------
define
define?
define!
set

Default Rulebase
----------------
Document the commands and philosophy of the default rulebase.
- ObjectRule.<ext>
- Installation via Install
- The use of Publish/$PUBLISH
  - find-project-bin
- Generate
- Defined variables
- subdirvars
- wildcards, Glob
- Document all the high-level rules
- Document the low-level rules/helpers
- Unit tests (--interp, --chdir)

Orphan Targets
--------------
tmake maintains a cache of all targets which have previously been built.
This allows tmake to "know" when rules change such that a previous target
is no longer a target, and thus the old file can be discarded.

The low level commands, get-orphan-targets and discard-orphan-targets are wrapped
by the high level phony target in rulebase.default, clean-orphans. This target can
be run manually, or automatically via the clean, distclean and test targets.

Consider the build.spec:

	Executable prog a.c b.c

$ make
Cc a.o
Cc b.o
Link prog
Built 3 target(s) in 0.09 seconds

Now assume that b.c is no longer required:

	Executable prog a.c

$ make clean
Clean 1 orphan targets
Clean .

Note that the orphan target, b.o is deleted even though
it is not mentioned in any rule.

Let's build again.

$ make
Cc a.o
Link prog
Built 2 target(s) in 0.07 seconds

And now change the name of the program.

	Executable newprog a.c

$ make       
Link newprog
Built 1 target(s) in 0.04 seconds

And clean orphans.

$ make clean-orphans
Clean 1 orphan targets

Caching Build Commands
----------------------
tmake caches the commands used to build a target so that it can automatically rebuild targets
where the commands have changed (e.g. a compile/link command line).

Consider:

	Executable prog a.c

Build with -v so we can see the actual commands:

$ tmake -v 
cc -Ipublish/include -I.  -c a.c -o a.o
cc   -o newprog a.o
Built 2 target(s) in 0.41 seconds

Now change the compiler flags:

$ tmake -v CFLAGS=-Os
cc -Ipublish/include -I. -Os -c a.c -o a.o
cc   -o newprog a.o
Built 2 target(s) in 0.09 seconds

If we don't change the flags, then no build is required.

XXX: Talk more about how this is accomplished and how only variables are subsituted, and
what happens if subst fails.

Tree Structure and 'local'
--------------------------
High-level rules assume that paths are local.
When using 'target' directly, use of [make-local].

publish
-------
The concept of publishing binaries, libraries and headers for sharing 

Cross Compiling
---------------
Currently tmake has poor support for intermixing host and target build "entities".
For example, if a complex generator application needs to be built on the host which
involved multiple libraries, and the use of autoconf/autosetup, this can't be done.

In this case, the suggestion is to break the build into two steps.

1. Build the host tools and stage them somewhere accessible
2. Build the target, with the built host tools now available

For simple cases, the following can be used instead.

a. Use a script-based generator if possible, rather than an executable generator
b. Use a simple host-executable rule such as the following:

	proc HostExecutable {target args} { 
		target [make-local $target] -inputs {*}[make-local {*}$args] -do { 
			run $CC_FOR_BUILD -o $target $inputs 
		} 
		Clean $target 
	} 

Integration with autosetup
--------------------------
settings.conf
tmake.tcl
jimsh0

Integration with kconfig or similar
-----------------------------------
ifconfig, etc.
return -code 20

Creating Installation Trees
---------------------------
The idea of Install and 'make install' where a target tree/filesystem is created.

Out-of-tree Builds
------------------
Discuss builddir, srcdir, -C and implications

make wrapper
------------
Discuss gmake, bsdmake wrappers via generated Makefiles

make /clean vs make clean
tmake vs make
passing options to tmake via make

Dynamic Dependency Checking
---------------------------
Dynamic dependency checking is supported which allows a commmand (e.g. a file scanner)
to automatically determine dependencies.

Consider the following file, a.c

  #include <stdio.h>
  #include <common.h>
  #include "a.h"
  ...

And a.h

  #include "b.h"

The built-in rulebase automatically associates the built-in recursive regex scanner with
rules to build object files (.o) from source files (.c) via a rule which looks like:

a.o: a.c
dyndep=header-scan-regexp-recursive $INCPATHS $HDRPATTERN
  var INCPATHS=publish/include .
    run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

Note that the 'dyndep' attribute specifies a command prefix to run which will
return a list of dependent targets/files.

The built-in scanner:

* Uses a regex to scan for dependencies of the form #include ...
* Ignores conditional compilation (#ifdef, etc.)
* And thus is conservative in that it make create an unnecessary dependency (but not the reverse)
* Is recursive, so that in the example above, a.o depends upon both a.h and b.h
* Knows if a dependency is:
  * a target, and thus must be generated before being scanned recursively
  * an existing source file, and thus creates a time-based dependeny
  * missing, and thus assumed to be a system header, and ignored
* Caches the results of the scan to avoid unnecessary scanning
* Carefully checks to see that the scan would return the same results as
  the cache to ensure that changes such as creating files in-tree which
  shadow system headers cause a rebuild

Dynamic dependencies:

* Are cached, along with the command (paths, pattern, ...), so that the (small) cost of scanning is only incurred when the file changes
* The set of dependencies is cached. If this set changes, the target is rebuilt.
  This can occur if a system header was previously shadowed by a source file, but
  the build changes so that this no longer occurs.

Reliability
-----------

* Various things are cached to ensure that targets are rebuilt when 

Parallel Builds
---------------
tmake does not currently support parallel builds, but this is an implentation detail.
With some (much!) restructuring, parallel builds should be possible.

More about cached state
-----------------------
Explain what is in .makecache and the consequences of deleting it

Debugging
---------
Explain the various debugging "types" and how to use them when things go wrong.

Explain tmake --find=rule

Explain tmake --showcache

Jim Tcl vs Tcl
--------------
Downside of Tcl is that quitting the build with ^C fails to write the make cache.
One approach is to write the cache after every change!

Bootstrapping tmake
-------------------
Same explanation of tclsh/jimsh vs jimsh0 as for autosetup

Variables
---------
define! - defines a var and marks it as "fixed", which means that only define! can overwrite it
define  - defines a var, overwriting any existing definition
define? - defines a var only if it wasn't previously defined or was ""
define-exists - checks to see if a var is defined
get-define    - gets the value of a defined variable
define-append - defines a var if it doesn't exist or is "", or appends (with a space) if it does

Note that only variables defined in the top level project.spec and
build.spec, and the rulebase (rulebase.default or rulebase.spec)
are propagated to subdirectories. Any variables defined subdirectory
build.spec files are only valid for the remainder of that build.spec
file.

For example, IncludePaths can be used in project.spec or the top level build.spec
to set paths (via $INCPATHS) for all directories. However when IncludePaths is used
in a subdirectory, it affects *only* that subdirectory.

Also see the -vars and -getvar rule options which allow a variable to be bound to a rule.

Experiences with porting projects to tmake
------------------------------------------

polarssl
~~~~~~~~
Project has plain Makefile and cmake support.
Currently configuration is done my manually modifing Makefile and
include/polarssl/config.h

- Install autosetup and tmake
- Create basic auto.def to allow configuration of some options and checking
  some basic compiler settings. Most settings are still hard-coded here.
- Creates settings.conf and include/polarssl/autoconf.h
- Modify include/polarssl/config.h to include autoconf.h (to avoid overwriting current version)
- Currently tmake only supports building polarssl as a static lib
- Created polarsslwrap based on axtlswrap
- Test directory uses code generation. scripts/generate_code.pl was hard to work with
  because it wanted to generate output in the current dir.
  I changed it slightly to take the full path to the target on the command line.

=> Need support for shared lib
=> polarsslwrap does not work on Windows because of the lack of fork, exec, poll
=> Need add all possible options to auto.def, including dependencies

Build times?
