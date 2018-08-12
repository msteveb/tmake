This project tests source files changing during a build.

The source, a.in, is modified during the build.

First build:

$ tmake -dbB
    7ms [b T] Building target all
    8ms [b] all is phony, so rebuilding
    8ms [b] a doesn't exist, so rebuilding
    8ms [b] Building a <= all with rule @build.spec:1
Simulating writing inputs during build
Built 1 of 1 target(s) in 1.02 seconds

Now second build will detect changed mtime of a.in.

<stevebmac-818> tmake -dbB
   11ms [b T] Building target all
   11ms [b] all is phony, so rebuilding
   12ms [b] Deps for a have changed, so rebuild
   12ms [B] old hash: a.in 1534052578693907
   12ms [B] new hash: a.in 1534052595190186
   12ms [b] Building a <= all with rule @build.spec:1
Simulating writing inputs during build
Built 1 of 1 target(s) in 1.02 seconds

The same thing works with hashes. First build:

$ tmake distclean
    DistClean    .
$ tmake -dbB --hash
   31ms [b T] Building target all
   31ms [b] all is phony, so rebuilding
   31ms [b] a doesn't exist, so rebuilding
   37ms [b] Building a <= all with rule @build.spec:1
Simulating writing inputs during build
Built 1 of 1 target(s) in 1.05 seconds

The second build finds a different hash

$ tmake -dbB --hash
   13ms [b T] Building target all
   13ms [b] all is phony, so rebuilding
   19ms [b] Deps for a have changed, so rebuild
   19ms [B] old hash: a.in md5:ac5ffc67d8b7cde5ccab98e2442928e7
   19ms [B] new hash: a.in md5:e43d1b5c5ba11e4001e7bf9cf633b2db
   20ms [b] Building a <= all with rule @build.spec:1
Simulating writing inputs during build
Built 1 of 1 target(s) in 1.03 seconds
