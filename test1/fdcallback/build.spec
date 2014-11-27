PublishIncludes fdcallback.h

# Experiment with scopes
Scope {
	UseLibs timer

	SharedLib --publish --install=/lib --version=1.2.3 fdcallback fdcallback.c
	Executable --test testfdloop testfdloop.c
}

# This executable won't use either the timer lib, nor the fdcallback lib
Executable --test testdummy testdummy.c
