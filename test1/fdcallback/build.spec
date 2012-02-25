PublishIncludes fdcallback.h

UseLibs timer

SharedLib --publish --install=/lib --version=1.2.3 fdcallback fdcallback.c
Executable --test testfdloop testfdloop.c 
