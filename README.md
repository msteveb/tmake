Overview of tmake
-----------------
tmake is a usable, proof-of-concept, advanced build system.

It has perfectly acceptable performance for small projects (~1000 files),
but slows down beyond that.

What it does have:
- Build descriptions are succinct and declarative
- A real language for build descriptions (Tcl) and build actions, with simple conditional syntax
- Rules can create multiple files
- Two-stage reparsing allows build configurations to be generated and reloaded
  (e.g. via configure or kconfig)
- Cache of built targets allows for:
  - Cleaning orphan targets
  - Rebuilding if build commands change
  - Rebuilding if the target is to be built by a different rule
  - A file is "up-to-date" if its rule runs, even if the file didn't change (virtual mtime)
- Good support for "generators" that generate sources
- Dynamic dependency support, including caching dependencies and support for generated files
- Excellent debugging facilities to identify exactly what is occuring and why
- 'tmake --find' to find specific rules
- Support for out-of-tree builds
- Non-recursive
- Automatic creation of directories as required
- Common operations (mkdir, rm) can be done without forking a process
- Add additional dependencies, bound vars, etc. to existing rules
- tmake --genie for fast-start
- Requires jimsh, the Jim Tcl interpreter to run

Essentially almost everything listed here: http://www.conifersystems.com/whitepapers/gnu-make/
is addressed, except performance.

Simple things are simple
------------------------

Consider the following example of building a library and an executable
that links against the library. The build description is simple, succinct
and has a minimum use of punctuation.

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

TODO Items
----------
- Documentation, especially basic --help documentation, and developer docs (e.g. known rules)
- Address known issues below, if possible
- Do we need a -vars variant which completely replaces the var?
- Lots of windows support
- Do we need tmake --rootok to support the ability to run a build as root?

High Level vs Low Level Rules
-----------------------------
The core tmake essentially has a single command to create a rule, target.
While it would be possible to create a build description purely with the 'target' command,
tmake is designed to layer a higher-level set of build commands, a "rulebase".

The default rulebase includes such a set of high level rules, such as Executable,
ArchiveLib, SharedObject, Phony, Install and more.

The default rulebase may be extended or replaced, or rules tweaked
with the low level 'target' as required.

Documentation for the 'target' command
--------------------------------------
All build rules are constructed using the 'target' command:

  target ruletarget arg...

e.g.

  target blah -depends <lib>foo -inputs a.o b.o -do { run $CC -o $target $inputs }

Arguments to 'target' take the form '-key1 values... -key2 ...', where all subsequent
values are considered to belong to a key until the next key. This approach make
it very easy to compose rules by simply appending keys and values.

Note that many keys are simple flags and do not expect any values.

-alias newname
    Create an alias for the target, e.g. <lib>name.
	See the section on Aliases for more information.

-depends args
	List of files/targets upon which this target depends.
	These targets are available to the -do command as $depends
	Note that -inputs are automatically added to -depends.

-inputs args
	List of files/targets which are used by the -do command to create the target.
	These targets are available to the -do command as $inputs.

-do command
	Tcl script to run when the target needs to be built.
	Unless the target is phony, the -do command *must* create the given target(s).
	The standard variables are set for the rule ($inputs, $target, etc.)
	See 'Variables available to commands'

-hash
    If 'UseHashing on' is set, tmake will only compute hashes for source files,
	not targets. If this is set on a rule, any checks for the target being out
	of date will be made using a hash rather than a timestamp.
	This is useful if the build command updates the file with unchanged contents.

-symlink
    Should be set if the target is a symlink, so that the existence and timestamp
	of the target is used rather than what the target points to.

-phony
	Marks the target as phony. A phony target is considered to always need building
	and any file with the same name is ignored. Typical phony targets are: all, clean, test, install

-nofail
	Failure of the '-do' commands for the rule is ignored.

-rootok
	Normally, the '-do' commands for a rule will refuse to run if being run as root.
	This option disables the check for this rule. See the section below on installation
	as root for the rationale for this option.

-onerror command
	Tcl script to run if the command fails. Allows for cleanup, e.g. of
	temporary files.

-msg command
	Tcl script to run when the rule is invoked to build the target.
	Should be succinct to avoid excess output in the normal case.
	For example, the default object rule for .c files uses:

	  -msg {note Cc $target}

-dyndep command-prefix
	Tcl command prefix invoked to extract dynamic dependencies from each of the dependencies.
	Returns a list of dependencies. See header-scan-regexp-recursive and ObjectRule.c
	in rulebase.default for an example.

-vars name value ...
	Binds the names to the values for the rule.
	Before invoking Tcl commands associated with -do, -msg, -onerror and -dyndep, variables (defines) are
	created/set according to any bound variables. For example, in the following rule, $C_FLAGS
	and $INCPATHS are set to the given values before the -dyndep and -do scripts are run.
	Compare this with $CCACHE, $CC and $CFLAGS which are global variables (defines),
	and thus are the same for all rules.

	Note that if a name is specified with -var multiple times (possibly in multiple rules), the values accumulate
	(with a space separator). Consider the rule created by:

	  Objects auth.app.c

		authapp/auth.app.o: authapp/auth.app.c
		dyndep=...
		local=authapp
		  var C_FLAGS=...
		  var INCPATHS=include publish/include authapp
				run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

	Let's add an include path to this rule:

	  Depends auth.app.o -vars INCPATHS axtls

	Now the new rule is:

		authapp/auth.app.o: authapp/auth.app.c
		dyndep=...
		local=authapp
		  var C_FLAGS=...
		  var INCPATHS=include publish/include authapp axtls
				run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

-getvars name ...
	Similar to -vars, except that the value of the variable is taken from current value
	of the global variable (define)

-chdir
	Normally all commands are run from the top level *source* directory.
	If -chdir is given, commands for this target are run from the local *build* directory
	(objdir) instead. i.e. for a -chdir rule in directory 'abc', the rule is run from objdir/abc.
	This is most often used for unit tests or generators which make assumptions
	about the current directory. It should be avoided where possible.

-nocache
	Do not cache this rule. Note that the 'Install' command from rulebase.default
	uses -nocache for performance reasons since install targets are never used
	as dependencies.

The following options are experimental and may be removed in the future.

-add
	Normally only one rule for a target may contain -do. With -add, -do commands
	may be added to an existing rule.

-fatal
	If the target fails to build, exit immediately (like tmake -q) rather than building
	other, non-dependent targets.

On Directories
--------------

Normally everything is relative to the top level source directory.
To compile dir/a.c and produce objdir/dir/a.o, a command such as the following
is run from the top level source directory.

  cc -c dir/a.c -o objdir/dir/a.o

Normally this works well, but some tasks, especially tests and generator commands
may expect to find support files locally, or find output files in the local source
or target directory. tmake supports this as follows:

1. 'target -chdir' causes the task '-do' to be run from the local build directory.

The following are all implemented in rulebase.default

2. Test targets (from rulebase.default) set the $SRCDIR environment variable
   to point to the local source dir.

   Consider the following two tasks in local subdir, "dir":

   Test test1
   Test --chdir test2

   In the first case, $SRCDIR will be "dir", while in the second it will be "../../dir"
   If the test program/script needs to reference support input files in can find them relative to $SRCDIR.

3. Similarly, if 'Generate' is given the '--chdir' flag, it creates a 'target -chdir' rule and also
   uses this directory specification to find the script or interpreter.

Environment Variables
---------------------

$TOPSRCDIR   - absolute path to the top of the source tree (where project.spec lives)
$TOPBUILDDIR - absolute path to the top of the build tree (by default, $TOPSRCDIR/objdir)
$BUILDDIR    - relative build directory, specified by --build (by default, objdir)

rulebase.default also sets the following for Test targets:

$SRCDIR      - relative source directory. Depends on with -chdir is in effect.

Environment variables may be set with 'setenv' and retrieved with 'getenv'

Note that the environment is saved/restored for each '-do' command.

Variables available during parsing
----------------------------------
Add 'define' variables are available as Tcl variables during the parsing phase.
This includes the system defined variables:

$TOPSRCDIR          Absolute path to the root of the project
$BUILDDIR           Relative path to the to build directory (default: objdir)
$TOPBUILDDIR        Absolute path to $BUILDDIR

In addition, rulebase.defaults defines many variables to support the high level rules.

Local Tcl variables may also be used. The lifetime of any such variables is through to the end
of the current file (e.g. build.spec, project.spec)

Variables available to commands
-------------------------------
In the -do clause of a command, the following variables are defined.

$targetname  - The name of the target(s) of the rule
$target      - The path to the target(s) of the rule ($BUILDDIR/$targetname)
$inputs      - Any files mentioned with -inputs
$depends     - Any files mentioned with -depends, plus any mentioned with -inputs
$local       - The (relative) source directory associated with the rule
$build       - The (relative) build directory associated with the rule - outputs should go here

In addition, any variables defined with 'define' (including variants) are available.

And any variables bound with -vars or -getvars (these take precedence over global 'define's)

What happens
------------
- parse options
- locate project top (project.spec)
- parse project.spec, rulebase.spec or rulebase.default, build.spec files
- Any files specified with Load are built if necessary
- If anything was built, the build.spec files are reparsed
- The specified targets are built

Aliases
-------
For most rules it is possible to identify the dependencies explicitly
by name. However in some circumstances the name of the target may not
be known at the point that the rule is created. Consider the case
where an executable needs to link against a library created in another
directory of the project.

  # In the directory creating the library
  Lib --publish foo foo.c

  # In the directory linking against the library
  UseLibs foo
  Executable bar bar.c

In order for this to work, the library in question needs to be
published. However the executable linking against the library doesn't
know whether the library will be a shared library or archive library,
and thus it can't add a dependency on the published library file.

The answer is for the Lib rule to create an alias for the target file.
If the library as created as an archive library, we will have:

  targetalias <lib>foo $PUBLISH/lib/libfoo.a

Then, the executable can depend and link against <lib>foo which will
be resolved via the alias to the underlying target. Note that the alias
name can by anything, but the "<type>name" convention is used to avoid
conflict with real files or targets.

Selecting files by globbing
---------------------------
Glob, Glob --recursive, etc.
Automatic Glob by ArchiveLib, SharedLib, Executable
Automatic Glob plus renaming for Publish, PublishIncludes, Install

project.spec, build.spec, rulebase.spec, rulebase.default, autosetup/
---------------------------------------------------------------------
- reparsing after project.spec
- subdirvars
- BuildSpecProlog/BuildSpecEpilog

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
tmake maintains a cache of all targets that have previously been built.
This allows tmake to "know" when rules change such that a previous target
is no longer a target, and thus the old file can be discarded.

Note that rulebase.default overrides delete-orphan-files to move orphans
to .trash/ instead of deleting them immediately. This is useful if a generated
file is replaced with a source file and the source is misidentified as an orphan.
The deleted orphan can be manually reinstated from .trash/, until 'tmake clean' is run,
at which point all files from .trash/ are deleted.

Consider the build.spec:

	Executable prog a.c b.c

$ tmake
Cc a.o
Cc b.o
Link prog
Built 3 target(s) in 0.09 seconds

Now assume that b.c is no longer required:

	Executable prog a.c

$ tmake clean
Clean 1 orphan targets
Clean .

Note that the orphan target, b.o is deleted even though
it is not mentioned in any rule.

Let's build again.

$ tmake
Cc a.o
Link prog
Built 2 target(s) in 0.07 seconds

And now change the name of the program.

	Executable newprog a.c

$ tmake
Link newprog
Built 1 target(s) in 0.04 seconds

And clean orphans.

$ tmake clean-orphans
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
Normally any files referred to in a build.spec relate to files found in that directory,
but sometimes files need to be shared across directories.  Typically this will be:
- Header files
- Host executables and scripts
- Libraries

Instead of having each command that needs these things refer
to the various directories that contain them, we "publish" these
shared files to a top level directory, such as 'publish'
Ideally we do this with hard links (if supported) so that
if an error occurs (say in a header file) and the file is edited,
it will be the original file that is edited.
If hard links aren't supported, soft links or simply copying will work too.

Unlike Install where the installed files are never dependencies, these
published files become the dependency via the chain:

  dir2/target.o <- publish/include/file.h <- dir1/file.h

A typical scenario is where a library and some header files need to be exported
from a directory. build.spec would look something like this.

  PublishIncludes public1.h public2.h
  # Private header files are not published
  Lib --publish my file1.c file2.c file3.c

This will publish publish/include/{public1,public2}.h and publish/lib/libmy.a where
they will be available for targets in other directories.

To publish an executable (say, needed during the build):

  HostExecutable --publish generate generate.c

Now the directory that uses these published files does something like:

  # Note that published header files are found automatically

  Generate table.c <bin>generate input.txt {
    run $script $inputs >$target
  }
  Executable xyz main.c table.c <lib>my

Here we use <bin> and <lib> alias selectors to refer to the corresponding published targets.

Note that the publish dir can be changed from the project.spec file. e.g.

  define PUBLISH .publish

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

For comparison, cmake has some support for option (1). See http://www.vtk.org/Wiki/CMake_Cross_Compiling
section "Using executables in the build created during the build"

In the future a "context"-based approach could be used. The idea is that each separate context
has it's own:

- set of define variables
- targets
- build directory tree

Consider the following (mythical) build fragment:

  Context default {
    define CPFLAGS -f
    target a -inputs b -do {
        run cp $CPFLAGS $inputs $target
    } -getvars CPFLAGS
  }

  Context host {
    define CPFLAGS -p
    target a -inputs b -do {
        run cp $CPFLAGS $inputs $target
    } -getvars CPFLAGS
  }

This keeps two distinct rules. If we use #xxx#name to represent 'name' in context 'xxx', we have:

  a: b
    var CPFLAGS=-f
      run cp $CPFLAGS $inputs $target

  #host#a: #host#b
    var CPFLAGS=-p
      run cp $CPFLAGS $inputs $target


The 'default' context omits the #context# prefix for simplicity, but can be name explicitly if required.
Sources and targets with different contexts can be used by using an explicit prefix.

All this means it is possible to do:

  Context host {
    define CC $CC_FOR_BUILD
    Executable --publish generator generator.c
  }

  Generate out <bin>#host#generator in {
    run $script $inputs $target
  }

Anything declared outside 'Context' uses the 'default' context.
There would need to be convention for mapping context to output directory.
If we simply use objdir/<context>/... there may be a naming conflict.
Could use object.<context> or could use objdir/default/ for the default
context instead of just objdir/

How does Load work? For example, $CC_FOR_BUILD may be loaded only in the default
context. Do we need to use ${#default#CC_FOR_BUILD} ?

symlink targets
---------------
tmake normally uses stat() to validate that the targets of rules were created,
and to determine the modification time of those targets. However if a target
is a symlink, lstat() should be used instead. This is especially notable
if the target is a dangling symlink. The -symlink flag indicates to tmake that the
target is a symlink.

Note that if a rule has multiple targets, lstat() is used on all targets.
This will normally be ok, even if only one of the targets is a symlink as lstat()
will return the same as stat() in this case.
(Is there a case to always use lstat() on targets?)

Integration with autosetup
--------------------------
settings.conf
tmake.tcl
jimsh0
--build
$BUILDDIR

Integration with kconfig or similar
-----------------------------------
ifconfig, etc.
return -code 20

Creating Installation Trees
---------------------------
The idea of Install and 'make install' where a target tree/filesystem is created.
Also discuss -rootok here.

Out-of-tree Builds
------------------
Discuss builddir, srcdir, --build, -chdir and implications
In particular, note that rules run from $TOPSRCDIR and should
create targets under $build

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
dyndep=header-scan-regexp-recursive $INCPATHS "" $HDRPATTERN
  var INCPATHS=publish/include .
    run $CCACHE $CC $C_FLAGS $CFLAGS -c $inputs -o $target

Note that the 'dyndep' attribute specifies a command prefix to run which will
return a list of dependent targets/files.

The built-in scanner:

* Uses a regex to scan for dependencies of the form #include <abc.h> or #include "abc.h"
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

XXX: Note that "#include INCLUDEFILENAME" is not supported. Suggest workarounds.

Reliability
-----------

* Various things are cached to ensure that targets are rebuilt when required.

Note that currently we only cache the script which generates targets, not
how that script resolves.

However 'run' will cache the details of external programs (path, size, mtime) if
'CheckExternalCommands on' is set and will rebuild if the external program changes.

Parallel Builds
---------------
tmake now supports parallel builds on platforms with os.fork.
--jobs
define MAXJOBS

More about cached state
-----------------------
Explain what is in .makecache and the consequences of deleting it

tmake --showcache

Debugging
---------
Explain the various debugging "types" and how to use them when things go wrong.

Explain tmake --find=rule

Why Jim Tcl?
------------
Explain the use of Tcl.
Then why not big Tcl? Originally tmake supported both Tcl and Jim Tcl, however Tcl had a number
of issues so that now only Jim Tcl is supported. These include:
- No signal handling, so quitting the build with ^C fails to write the make cache.
- Tcl does not have the detailed source location support
- No os.fork/wait
- Tcl differentiates between array and dict, which makes code messier

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

Multiple Targets on the Command Line
------------------------------------
Explain how rulebase is parsed, then the build descriptions, 
then any 'Load' targets are built, and if necessary, the build descriptions are re-read.
Also, the target status is reset after every target.

clean, distclean and clean-orphans are special
----------------------------------------------
In that they don't causing building of the Load targets.
Additional clean targets can be added with 'add-clean-targets'

Reinvoking the Build
--------------------
Consider the following project.spec:

	====================================================
	Load user.conf

	Phony default -do {
		file copy -force [file-src default.conf] user.conf
	}
	Phony debug -do {
		file copy -force [file-src debug.conf] user.conf
	}
	====================================================

The user configuration is loaded from user.conf, which is assumed
to be created externally. Two phony targets (actions) also exist
which can set a specific configuration. It is now possible to set
the configuration and rebuild with the command line:

    $ tmake default all

It might be desirable for the single action to both update the configuration
and rebuild. One way to do this may be with a recursive invocation of tmake:

	====================================================
	Load user.conf

	Phony default -do {
		file copy -force [file-src default.conf] user.conf
		run [info nameofexecutable] $::argv0 all
	}
	====================================================

However this is cumbersome and inefficient. A better way to achieve this
is to have the rule re-add a new target.

	====================================================
	Load user.conf

	Phony default -do {
		file copy -force [file-src default.conf] user.conf
		add-build-targets all
	}
	====================================================

In this case, once the rule has run, a new target is added 
to the build, as if added on the original command line.
If the target was already on the command line, this has no effect.

Libraries from Archive Libraries
--------------------------------
Under some circumstances it is necessary to build a target from targets
across multiple subdirectories. Consider the following (abbreviated) example from libgit2.

	====================================================
	$ tree libgit2
	libgit2
	|-- deps
	|   |-- http-parser
	|   `-- zlib
	|-- include
	|   `-- git2
	|-- src
	|   |-- transports
	|   |-- unix
	|   `-- win32
	|-- tests
	`-- tests-clar
		|-- attr
		|-- buf
		|-- object
		|   |-- commit
		|   |-- raw
		|   `-- tree
		|-- odb
		`-- status
	====================================================

The final target is either an archive library (libgit2.a) or a shared library (libgit2.so)
It is composed of groups of objects from deps/http-parser, src, src/transports and possibly
deps/zlib and src/unix or src/win32.

It would be possible to build the library at the top level from objects in lower
levels, for example:

	====================================================
	Lib git2 deps/http-parser/*.c src/*.c src/unix/*.c
	====================================================

However this forces all of the build rules (CFlags, IncludePaths, etc.) to
be specified at the top level. It is better if the components can be
built individually and then combined to form the final library.
tmake supports this by allowing library objects to be combined into other archive
and shared libaries. This is done as follows.

	=== deps/http-parser/build.spec ====================
	Lib --publish http-parser *.c
	====================================================

	=== src/build.spec =================================
	Lib --publish src *.c transports/*.c unix/*.c
	====================================================

	=== build.spec =====================================
	Lib git2 <lib>http-parser <lib>src
	====================================================

The special objects selector, <lib>name, is used
to select all the objects from the corresponding published library.

(Note that this is related to the mechanism which allows published
libraries to be found by other components with UseLibs)

When the inputs to the git2 library are collected, the selector
such as <lib>src is replaced with the *objects* that are listed
as inputs to the src library. In addition, a dependency on the 'src'
library is added to the 'git2' library to ensure that the objects
are available when required.

This approach has the advantage that the aggregate library can be created
in any directory, not just a parent of each of the component libraries.

The same mechanism can be used for creating a shared libraries from other
libraries, and both shared and archive libraries can be used as the component
libraries.

Note 1: The <lib> selector selects the *objects* from the component library, not the library itself.
Note 2: The component library must be published in order to be available.
Note 3: When creating an aggregate shared library, the appropriate compile flags (e.g. $(SH\_CFLAGS)
        must be added to objects in the component libraries. tmake is not able to automatically
        determine if this restriction has been followed.

Experiences with porting projects to tmake
------------------------------------------

polarssl
~~~~~~~~
Project has plain Makefile and cmake support.
Currently configuration is done by manually modifing Makefile and
include/polarssl/config.h

- Install autosetup and tmake
- Create basic auto.def to allow configuration of some options and checking
  some basic compiler settings. Most settings are still hard-coded here.
- Create settings.conf and include/polarssl/autoconf.h
- Modify include/polarssl/config.h to include autoconf.h (to avoid overwriting current version)
- tmake can build either static lib or shared lib
- Created polarsslwrap based on axtlswrap
- Test directory uses code generation. scripts/generate\_code.pl was hard to work with
  because it wanted to generate output in the current dir.
  I changed it slightly to take the full path to the target on the command line.

=> polarsslwrap does not work on Windows because of the lack of fork, exec, poll
=> Need to add all possible options to auto.def, including dependencies

Build times:
- About 2 seconds for tmake
- About 4.5 seconds for cmake

libgit2
~~~~~~~
Was waf, now cmake
- Installed autosetup and tmake
- Converted autoconfig + user config from cmake to auto.def

- Required addition of building libraries from libraries
- Required addition of GlobRecursive (now Glob --recursive --exclude=...)
- Added Template support as tmake module for .pc (pkg-config)
- tests-clar/clar was awkward since it wouldn't generate sources out-of-tree.
  Needed to manually move them to the build tree. (Alternatively, could have modified clar).
- Probably need PublishIncludes --dir=<subdir>

* Didn't do thread support
* tmake currently doesn't support MSVC, but I left in as much support as possible
* Now uses pkg-config support for zlib searching

fossil
~~~~~~
- A number of HostExecutable generators are used
- Most of these could be easily replaced with Tcl commands or scripts

nethack4
~~~~~~~~
- Avoiding 'sudo tmake install' creating build files as root
- There were some recursive dependencies that required subset libraries to be created
- date.h was being recreated every time

Differences with make
---------------------
- Differentiates between rule 'inputs' and 'dependencies'
- Allows binding of values to variables during the definition phase which are
  then available to the command(s) at run time.
- Commands are Tcl scripts, which means that many operations do not require a fork/exec
- The 'run' built-in runs external commands
- Commands used to build a target a cached so that if commands change, rules are re-run
- Automatic directory creation

Future Plans
------------
While the proof-of-concept works very well, performance can be an issue for large projects.
I expect that a production version will use a C/C++ implementation for the
core build engine, with an embedded Jim Tcl interpreter for scripting.

Hash-based Dependency Checking
------------------------------

Hash-based comparison vs Time-based comparison can be enabled with 'UseHashes on|off'
in project.spec, or 'tmake --hash' (for testing) . The default is time-based comparison.

Consider the following rules:

a <= c d
b <= c d

When deciding whether to build a we need to look at the previous hashes and the current hashes of c and d.
Consider the case where the target previously ran and the hash dependency hashes were
recorded in the cache.

dephashes(a) = c hash(c)|d hash(d)

Now when deciding whether to build a, we compute hashes of all it's dependencies.
If we get the same answer as the saved dephashes(a), there is no need to build.

If it is different, we update dephashes(a) in the cache and continue to build.
It is OK if we update the cache and then the build fails, because the build will rerun next time
(for the same reason it ran the this time).

There a few extra things to consider.

* If the targets need to be built for for some other reason (e.g. does not exist), the
  hash of dependents is not computed immediately. Rather the check is done after
  all the dependents are successfully created.

* Rather than compute the hash every time, we store the mtime and hash of dependencies
  in the cache. If the mtime matches what is stored in the cache, the hash is used from the cache.
  Otherwise the hash is computed and the cache entry is updated.

* It would be expensive to compute hashes of possibly large generated targets. And generated files
  should only be generated by the build system, so we can expect their mtimes to change when they are
  created/modified - so use mtime is used as a proxy for the hash for targets. If the mtime changes
  (either forwards or backwards), the file is considered to have changed.
  If it is desired to use hashing on certain targets, use -hash that corresponding rule
  to force a hash check rather than a time check.

* While switching from hash-based to time-based and back to hash-based builds can cause problems with
  out-of-date hashes as these are not updated when running time-based builds.
  For this reason, when switching to time-based, hashes are removed from the cache.

* The dynamic dependency cache was previously based on the mtime of files. For a hash-based build,
  the hash should be used instead. There is no problem in switching between the two, because a hash
  will never be confused with a time.

* Currently cache entries for old source files are never removed
  from the cache (the as for dynamic dependencies). This should
  not be a big problem in practice, but the cache can be pruned with
  tcache --cacheclean

Hashes are compued by running 'md5sum' (or md5, for MacOS) because it is a fast hash
with a low chance of collisions.

Known Issues
------------
Slows down with a large project

No support for non-unix platforms, e.g. msvc

Changing --build means that all orphans are forgotten since
the cached targets only include the path relative to $BUILDDIR.

The integration with autosetup works, but could be more seamless
