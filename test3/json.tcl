#!/usr/bin/env jimsh

# Encode Tcl objects as JSON
# dict -> object
# list -> array
# numeric -> number
# string -> string
#
# The schema provides the type information for the value.
# str = string
# num = numeric
# obj ... = object. parameters are 'name' 'subschema' where the name matches the dict.
# list ... = array. parameters are 'subschema' for the elements of the list/array.

# Top level JSON encoder which encodes the given
# value based on the schema
proc json.encode {value {schema str}} {
	json.encode.[lindex $schema 0] $value [lrange $schema 1 end]
}

# Encode a string
proc json.encode.str {value {dummy {}}} {
	return \"[string map [list \\ \\\\ \" \\" \n \\n / \\/ \b \\b \r \\r \t \\t] $value]\"
}
# If no type is given, also encode as a string
alias json.encode. json.encode.str

# Encode a number
proc json.encode.num {value {dummy {}}} {
	return $value
}

# Encode an object (dictionary)
proc json.encode.obj {obj {schema {}}} {
	set result "\{"
	set sep " "
	foreach k [array names obj] {
		if {[info exists schema($k)]} {
			set type $schema($k)
		} elseif {[info exists schema(*)]} {
			set type $schema(*)
		} else {
			set type str
		}
		append result $sep\"$k\":

		append result [json.encode.[lindex $type 0] $obj($k) [lrange $type 1 end]]
		set sep ", "
	}
	append result " \}"
}

# Encode an array (list)
proc json.encode.list {list {type str}} {
	set result "\["
	set sep " "
	foreach l $list {
		append result $sep
		append result [json.encode.[lindex $type 0] $l [lrange $type 1 end]]
		set sep ", "
	}
	append result " \]"
}

# vim: se ts=4:
