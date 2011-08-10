# Output data in a simple read-only uweb table.

# Create a new table. Return anonymous handle function.
# attrs is an optional name=value list of attributes. Normally just specify "class=xxxx".
proc table {{attrs {}}} {
	set table(table_attrs) $attrs
	set table(rowcount) 0
	lambda {cmd args} {table} {
		try {
			table_$cmd table {*}$args
		} on error {msg opts} {
			# Fix the message to be more helpful
			regsub {should be "table_(.*) hdl (.*)"} $msg {"$table \1 \2"} msg
			return {*}$opts $msg
		}
	}
}

# Internal function to reset a new row. Not called by user.
proc _table_row_reset {type hdl args} {
	upvar $hdl table
	set row $table(rowcount)
	set table($row,type) $type
	set table($row,tr_attrs) $args
	set table($row,colcount) 0
	incr table(rowcount)
}

# Start a new table header row.
# attrs is an optional name=value list of attributes. Normally just specify "class=xxxx".
proc table_hdr {hdl args} {
	upvar $hdl table
	_table_row_reset th table $args
}

# Start a new table data row.
# attrs is an optional name=value list of attributes. Normally just specify "class=xxxx".
proc table_dat {hdl args} {
	upvar $hdl table
	_table_row_reset td table $args
}

# Output a value to a row.
# value is the value to output
# attrs is an optional name=value list of attributes. Normally just specify "class=xxxx".
proc table_val {hdl value args} {
	upvar $hdl table
	set row [expr $table(rowcount) - 1]
	set col $table($row,colcount)
	set table($row,$col,value) $value
	set table($row,$col,attrs) $args
	incr table($row,colcount)
}

# Output the completed table.
proc table_write {hdl} {
	upvar $hdl table

	html eval table -list $table(table_attrs) {
		foreach row [range $table(rowcount)] {
			html eval tr -list $table($row,tr_attrs) {
				foreach col [range $table($row,colcount)] {
					html eval $table($row,type) -list $table($row,$col,attrs) {
						html escape $table($row,$col,value)
					}
				}
			}
		}
	}
}

# vim: se ts=4:
