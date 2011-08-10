# This package provides access to "cooked" status values

package require common
package require config
package require modulations

# Maps a modulation value to a text string
proc map_modulation {value} {
	try {
		return [lindex $::modn_by_code($value) 1]
	} on error e {
		return "$value (???)"
	}
}

proc map_attr_init {} {
	set ::map_attr {}
}

proc map_attr_add {attr} {
	if {!($attr in $::map_attr)} {
		lappend ::map_attr $attr
	}
}

proc map_attr_get {type} {
	if {$::map_attr ne ""} {
		return "$type=[join $::map_attr " "]"
	}
}

# Returns a dictionary of all the known status
# for the given modem and corresponding ODU
#
# Note that the values are cached
#
proc get_modem_status {m} {
	if {![info exists ::modem_status($m)]} {
		set d {}

		config_load

		# Load configuration settings first
		# Including global settings
		set d(independent) [config_get modem.mode]
		if {$d(independent)} {
			set d(enabled) [config_get modem${m}.enabled]
			set d(txmute) [config_get rf${m}.txmute.tmp]
			set d(modembad) 0
		} else {
			# Hot standby config. Config is from modem 1
			set d(enabled) [config_get modem1.enabled]
			set d(txmute) [config_get rf1.txmute.tmp]
			set d(hsmode) [config_get modem.hsmode]
			set d(modembad) [readfile [root]/supervisory/modctrl/m${m}bad 0]
		}

		# Now status settings
		set d(programmed) [readfile [root]/var/run/modem${m}_detected 0]
		set d(fitted) [readfile [root]/supervisory/global/modem${m}_detected 0]
		if {$d(enabled) && $d(programmed)} {
			set d(modemvalid) [readfile [root]/supervisory/modem$m/valid 0]
			set d(locked) [readfile [root]/supervisory/modem$m/frame_lock 0]
		} else {
			set d(modemvalid) 0
			set d(locked) 0
			set d(modemactive) 0
		}
		set d(rfvalid) [readfile [root]/supervisory/odu$m/valid -]
		if {$d(rfvalid) eq "1" && [readfile [root]/supervisory/odu$m/mismatch] eq "1"} {
			set d(rfvalid) -1
		}
		set d(ready) 0

		# Hot standby status
		set d(modemactive) 1
		# txconfig is 0 if modem1 is TX and 1 if modem2 is TX, so increment
		set d(txconfig) [readfile [root]/supervisory/global/modem2_tx_config 0]
		incr d(txconfig)
		# rxcurrent is 0 if modem1 is RX and 1 if modem2 is RX, so increment
		set d(rxcurrent) [readfile [root]/supervisory/global/modem2_rx_selected 0]
		incr d(rxcurrent)
		if {!$d(independent) && $d(txconfig) != $m} {
			set d(modemactive) 0
		}

		# The modem data is fitted, so there should be data
		if {$d(fitted)} {
			set d(txmod) [readfile [root]/supervisory/modem$m/tx_modulation -]
			set d(rxmod) [readfile [root]/supervisory/modem$m/rx_modulation -]
			set d(ber)   [readfile [root]/supervisory/errors/m${m}_ber -]

			# The RF/ODU data is valid, so load it
			set d(rxpower) [readfile [root]/var/odu$m/rx_power -]
			set d(txpower) [readfile [root]/var/odu$m/tx_power -]

			if {$d(enabled) && !$d(txmute) && $d(programmed)} {
				set d(ready) 1
			}
		}
		set ::modem_status($m) $d
	}

	return $::modem_status($m)
}

if {0} {
# Standard mapping for various status values
set status_mapping {
	rxmod {"Rx Modulation" {eval {map_modulation $value}}}
	txmod {"Tx Modulation" {eval {map_modulation $value}}}
}
}

proc map_show_alarm {value expected} {
	if {$value ne $expected} {
		map_attr_add alarmon
	}
	return $value
}

# Determine the main fitted/configured/enabled/muted status
proc map_modem_status {m} {
	set d [get_modem_status $m]

	if {!$d(fitted)} {
		if {$d(enabled)} {
			map_attr_add alarmon
		}
		return "Not Fitted"
	}

	if {!$d(enabled)} {
		return Disabled
	}

	if {$d(txmute)} {
		if {$d(modemactive)} {
			map_attr_add alarmon
		}
		return "Tx Muted"
	}

	if {!$d(programmed)} {
		map_attr_add alarmon
		return Offline
	}

	if {$d(modembad)} {
		map_attr_add alarmon
		return Failed
	}

	if {$d(locked)} {
		return Locked
	}

	if {$d(modemactive)} {
		map_attr_add alarmon
	} else {
		map_attr_add failed
	}
	return "Not Locked"
}

# Determine the tx status
proc map_tx_status {m} {

	set d [get_modem_status $m]

	if {!$d(ready)} {
		return -
	} elseif {$d(independent)} {
		# Indepedent mode is easy
		return Active
	} else {
		# In Hot Standby mode and the modem is Ready

		switch -glob $d(hsmode),$d(txconfig) \
			auto,$m {
				set val Active
			} \
			auto,? {
				if {$m == 1} {
					set val Inactive
					map_attr_add alarmon
				} else {
					set val Backup
				}
			} \
			$m,$m {
				set val "Active (Forced)"
				map_attr_add alarmon
			} \
			$m,? {
				# This modem is forced, but the other one is active!
				set val Bad
			} \
			?,$m {
				# Other modem is forced, but this one is active!
				set val Active
				map_attr_add alarmon
			} \
			default {
				# The other modem is forced and active
				set val Inactive
			}
		return $val
	}
}

# Determine the rx status
proc map_rx_status {m} {
	# Just the same as tx for now
	uplevel 1 map_tx_status $m
}

# vim: se ts=4:
