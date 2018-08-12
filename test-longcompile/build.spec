Depends a -inputs a.in -do {
	puts "Simulating writing inputs during build"
	sleep 0.5
	writefile a.in [rand]\n
	sleep 0.5
	file copy -force $inputs $target
}

Depends all a

Clean a
