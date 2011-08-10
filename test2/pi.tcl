proc pi {} {
 set n [expr {500 * 3}]
 set e 0
 set f {}
 for { set b 0 } { $b <= $n } { incr b } {
     lappend f 2000
 }
 for { set c $n } { $c > 0 } { incr c -14 } {
     set d 0
     set g [expr { $c * 2 }]
     set b $c
     while 1 {
         incr d [expr { [lindex $f $b] * 10000 }]
         lset f $b [expr {$d % [incr g -1]}]
         set d [expr { $d / $g }]
         incr g -1
         if { [incr b -1] == 0 } break
         set d [expr { $d * $b }]
     }
     append result [format %04d [expr { $e + $d / 10000 }]]
     set e [expr { $d % 10000 }]
 }
 puts $result
}

puts [time pi]
