package require fileutil

proc auth_session_dir {} {
	return [env HOST ""]/var/session
}

proc auth_create_session {expiry args} {
	while {1} {
		# Create a unique session key. 128 bits should do
		set key [format %x%x [rand] [rand]]
		if {$expiry > 0} {
			lappend args -expiry [expr {[os.uptime] + $expiry}]
		}
		if {[file exists [auth_session_dir]/$key]} {
			# Highly unlikely...
			continue
		}
		writefile [auth_session_dir]/$key $args\n
		break
	}
	return $key
}

# $action is "check" or "delete"
#
# Returns the list of name/value pairs if OK, or a list of {-error $msg} on error.
#
proc auth_check_session {action key args} {
	set info [readfile [auth_session_dir]/$key]
	if {$info eq ""} {
		return [list -error "No such session: $key"]
	}
	foreach {n v} $args {
		if {![info exists info($n)] || $info($n) ne $v} {
			return [list -error "Mismatch for value: $n"]
		}
	}
	if {$action eq "delete" || ![info exists info(-expiry)] || [os.uptime] > $info(-expiry)} {
		file delete [auth_session_dir]/$key
		if {$action eq "delete"} {
			return {}
		}
		return [list -error "Session expired: $key"]
	}
	return $info
}

# This proc is for use by auth.c: auth_get_username()
# Sets ::auth_username if the session is current
proc auth_get_username {} {
	catch {unset ::auth_username}
	set sessionid [cgi cookie get sessionid]
	set auth [auth_check_session check $sessionid ipaddr [cgi getenv REMOTE_ADDR]]
	if {[info exists auth(username)]} {
		# Looks good set the result
		set ::auth_username $auth(username)
	}
}
