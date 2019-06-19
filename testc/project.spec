# This test shows how to easily add a regexp-based dyndep rule

# This is the regexp pattern
define PARSER_INC_PATTERN {^[\t ]*include[\t ]+([^\t ]+)}
