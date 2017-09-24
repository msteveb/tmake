PublishIncludes fdcallback.h

# Experiment with scopes
Scope {
	UseLibs timer

	SharedLib --publish --install=/lib --version=1.2.3 fdcallback fdcallback.c
	Executable --test testfdloop testfdloop.c version.c

	# Add a version to testfdloop that is only updated when testfdloop is relinked

	# We only want to rewrite version.c if testfdloop needs linking
	# so make version.c depend on the dependencies of testfdloop except version.o

	# Find deps of testfdloop, ommitting version.o
	set deps [omit [get-rule-attr [make-local testfdloop] depends] [make-local version.o]]

	# And create the rule
	Depends version.c $deps -do {
		writefile $target "static const char version\[\] = \"@version@ [exec date]\";\n"
	}
	Clean version.c
}

# This executable won't use either the timer lib, nor the fdcallback lib
Executable --test testdummy testdummy.c
