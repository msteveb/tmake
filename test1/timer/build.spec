# As a test, keep local include files in a directory
PublishIncludes include/timer.h include/timerqueue.h

# Test building one object with different flags
ObjectCFlags timerqueue.c -DDUMMY_DEFINE

# And specify the object file here
Lib --publish timer timer.c timerqueue.c
