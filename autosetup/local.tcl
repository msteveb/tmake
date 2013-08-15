use cc

# If the compiler supports -Qunused-arguments, enable it
# This is to prevent clang from producing annoying messages
if {[cctest -cflags {-Qunused-arguments}]} {
	define-append CC -Qunused-arguments
}

