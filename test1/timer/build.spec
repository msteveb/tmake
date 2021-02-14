# As a test, keep local include files in a directory
PublishIncludes include/timer.h include/timerqueue.h

# Test building one object with different flags
ObjectCFlags timerqueue.c -DDUMMY_DEFINE

# And another with a variable string value
ObjectCFlags timer.c [quote-if-needed -DGITREV="[exec git describe --dirty]"]

# And specify the object file here
SharedLib --publish --version=1.0 timer timer.c timerqueue.c
