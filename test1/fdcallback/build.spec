PublishIncludes fdcallback.h

# Note that 
UseLibs timer

SharedLib --publish fdcallback fdcallback.c

#UseLibs fdcallback

Executable --test testfdloop testfdloop.c 
