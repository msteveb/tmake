package provide config

# Provides read/write access to the system config

proc config_dir {} {
	# If $HOST is set, it is used as the root instead of /
	# If $CONFIGDIR is set, it is used as the config dir, otherwise /etc/config
	return [env HOST ""][env CONFIGDIR /etc/config]
}

proc config_load {{filename {}}} {
	if {$filename eq ""} {
		set filename [config_dir]/config
	}
	set c [conf $filename]
	set ::config [$c get]
	$c close
	return $::config
}

proc config_save {{filename {}}} {
	if {$filename eq ""} {
		set filename [config_dir]/config
	}
	set c [conf $filename]
	$c set {*}$::config
	$c close -save
}

proc config_unload {} {
	array unset ::config
}

proc config_set {name value} {
	set ::config($name) $value
}

proc config_get {name {defaultvalue ""}} {
	if {[info exists ::config($name)]} {
		return $::config($name)
	}
	return $defaultvalue
}

proc config_names {} {
	array names ::config
}

proc config_read {filename} {
	set c [conf $filename]
	set vars [$c get]
	$c close
	return $vars
}

proc config_write {filename vars} {
	set c [conf $filename]
	$c set {*}$vars
	$c close -save
}
