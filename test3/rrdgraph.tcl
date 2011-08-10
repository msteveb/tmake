# Common functions for rrdtool graphing pages

proc rrdgraph {dbname graphname period} {

	switch -glob -- $period \
		d* {
			set duration day
			set info(start) e-1d
			set info(step) 300
			set info(type) AVERAGE
			set info(title) "24 Hours"
		} \
		m* {
			set duration month
			set info(start) e-1month
			set info(step) 3600
			set info(type) AVERAGE
			set info(title) "1 Month"
		} \
		w* {
			set duration week
			set info(start) e-7d
			set info(step) 900
			set info(type) AVERAGE
			set info(title) "1 Week"
		} \
		y* {
			set duration year
			set info(start) e-1year
			set info(step) 43200
			set info(type) AVERAGE
			set info(title) "1 year"
		} \
		* {
			set duration hour
			set info(start) e-1h
			set info(step) 30
			set info(type) LAST
			set info(title) "1 Hour"
		}
		set info(rrd) /var/run/$dbname.rrd
		set info(png) /tmp/rrd_${dbname}_${graphname}_${duration}.png
		set params {}

		lappend params -s $info(start) -e now -S $info(step)

	lambda {cmd args} {info params} {
		set params [rrdgraph.$cmd $params $info {*}$args]
	}
}

proc rrdgraph.close {params info} {
	lassign [info level 0] r
	rename $r ""
}

proc rrdgraph.stdinit {params info} {
	rrdgraph.size $params $info 620 200
}

proc rrdgraph.size {params info w h} {
	lappend params -w $w -h $h
}

proc rrdgraph.title {params info title} {
	lappend params -t "$title ($info(title))"
}

proc rrdgraph.ylabel {params info ylabel} {
	lappend params -v $ylabel
}

proc rrdgraph.comment {params info text} {
	lappend params COMMENT:[rrdgraph._escape $text]
}

proc rrdgraph.params {params info args} {
	lappend params {*}$args
}

# Modem 1, RF 1 are blue, Modem 2, RF 2 are green
proc rrdgraph._col {name} {
	set stdcol {
		m1 #1111AA
		rf1 #6666EE
		m2 #11AA11
		rf2 #66EE66
		up #888888
		super #FF5555
		m1 #1111AA

		m1frame #1111AA
		m1phase #6666EE
		m1timing #CCCCFF
		m1txlo #AA66FF

		m2frame #11AA11
		m2phase #66EE66
		m2timing #CCFFCC
		m2txlo #ECC93D
	}
	if {[info exists stdcol($name)]} {
		return $stdcol($name)
	}
	return "#888888"
}

proc rrdgraph._opts {name defaults arglist} {
	set opts $defaults
	array set opts $arglist
	if {![info exists opts(-col)]} {
		set opts(-col) [rrdgraph._col $name]
	}
	return $opts
}

# Escapes a label to convert \n to \\n and : to \\:
proc rrdgraph._escape {label} {
	string map [list \n \\n : \\:] $label
}

# Optional arguments are:
#    -col     graph colour, otherwise uses the std colour based on the name
#    -width   width of the line, otherwise 2
#    -label   label for the graph, otherwise none
#    -format  format string for the x axis, otherwise none
#    -units   units string, otherwise none
#    -multiplier multiply the raw value by this, otherwise 1
proc rrdgraph.line {params info name var args} {
	set opts [rrdgraph._opts $name {-width 2 -label "" -format "" -units "" -multiplier 1} $args]
	set opts(-label) [rrdgraph._escape $opts(-label)]

	lappend params DEF:$name=$info(rrd):$var:$info(type)
	lappend params CDEF:g_$name=$name,$opts(-multiplier),*
	lappend params LINE$opts(-width):g_$name$opts(-col):$opts(-label)
	if {$opts(-format) ne ""} {
		set opts(-format) [rrdgraph._escape $opts(-format)]
		set opts(-units) [rrdgraph._escape $opts(-units)]
		lappend params VDEF:min$name=g_$name,MINIMUM "GPRINT:min$name:Min $opts(-format)"
		lappend params VDEF:max$name=g_$name,MAXIMUM "GPRINT:max$name:Max $opts(-format)"
		lappend params VDEF:avg$name=g_$name,AVERAGE "GPRINT:avg$name:Avg $opts(-format) $opts(-units)\\n"
	}
	return $params
}

# Optional arguments are:
#    -col    graph colour, otherwise uses the std colour based on the name
#    -label  label for the graph, otherwise none
proc rrdgraph.area {params info name var args} {
	set opts [rrdgraph._opts $name {-label ""} $args]
	set opts(-label) [rrdgraph._escape $opts(-label)]

	lappend params DEF:$name=$info(rrd):$var:$info(type)
	lappend params AREA:$name$opts(-col):$opts(-label)
}

# Optional arguments are:
#    -col    graph colour, otherwise uses the std colour based on the name
#    -value  height of the line, otherwise 1
#    -width  width of the line, otherwise 2
#    -label  label for the graph, otherwise none
proc rrdgraph.bool {params info name var args} {
	set opts [rrdgraph._opts $name {-label "" -value 1 -width 2} $args]
	set opts(-label) [rrdgraph._escape $opts(-label)]

	lappend params DEF:$name=$info(rrd):$var:$info(type)
	lappend params CDEF:g_$name=$name,$opts(-value),*
	lappend params LINE$opts(-width):g_$name$opts(-col):$opts(-label)
}

proc rrdgraph.output {params info} {
	# If it was created less than 'step' seconds ago, don't recreate
	set now [clock seconds]
	if {![file exists $info(png)] || [file mtime $info(png)] < $now - $info(step)} {
		# Note we use locking here to avoid trying to create multiple graphs at once
		exec setlock /var/run/rrdgraph.lock rrdtool graph $info(png) {*}$params
	}

	cgi nodisplay

	cgi http header Content-Type image/png
	cgi http header Content-Length [file size $info(png)]
	cgi http response 200

	set f [open $info(png)]
	$f copyto stdout
	$f close
}

proc rrdgraph.debug {params info} {
	puts [list rrdtool graph $info(png) {*}$params]
}
