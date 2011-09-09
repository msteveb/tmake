# Waf 2.1.3

# Note that the dependency causes src/ping to be printed first
Phony ping src/ping -do {
	puts "-> ping from $local"
}
