# Helper package for working with javascript

package provide javascript

# javascript escape <string>
#
#   Escapes single quote and backslash in the string and returns the result
#
# javascript script <script>
#
#   Outputs a <script type=text/javascript> element containing the given script.
#
proc javascript {cmd args} {
	switch $cmd \
		escape {
			return [string map [list \\ \\\\ ' \\'] [lindex $args 0]]
		} \
		script {
			html eval script type=text/javascript {
				html puts [lindex $args 0]
			}
			return
		}

	error "javascript: Unknown command $cmd"
}
