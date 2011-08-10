package provide toolbars 1.0
package require fileutil
package require common
package require config

config_load

# Terminal Id
html str div class=terminalid [config_get system.id]

# Network/Backup Image toolbar item
set cmdline [readfile /proc/cmdline]
if {[string match "*root=/dev/mtdblock4*" $cmdline]} {
	html eval div class=backupinfo {
		html puts "Backup Firmare Active"
	}
} elseif {[string match "*root=/dev/ram0*" $cmdline]} {
	html eval div class=backupinfo {
		html puts "(netboot)"
	}
}

# DHCP enabled
if {[config_get net.dhcpclient 0]} {
	html eval div class=backupinfo {
		html puts "(dhcp)"
	}
}

if {[file exists /var/run/super.special]} {
	html eval div class=backupinfo {
		html puts "(super.bit)"
	}
}

# Any major alarms?
if {[file exists /var/run/web-alarms]} {
	set major 0
	foreach line [split [readfile [root]/var/run/web-alarms] \n] {
		lassign [split $line ,] stamp name pri val
		if {$pri eq "major"} {
			incr major
			break
		}
	}
	if {$major} {
		html eval div class=alarmtoolitem {
			html str a "title=Major Alarms Present" href=alarms "alarms"
		}
	}
}

# In switch.isolate1 mode
if {[config_get switch.isolate1 0]} {
	html eval div class=backupinfo {
		html puts (isolate1)
	}
}

# Installer mode
if {[config_get install.mode.tmp 0]} {
	html eval div class=installmodeinfo {
		html str a title=Installer href=installmode "(install mode)"
	}
}

# Logout toolbar item
if {[cgi auth username] != "" && [cgi auth status] == 1} {
	html eval div class=logout_link {
		html str a id=logout_link href=login?action=1 title=Logout Logout
		html escape " [cgi auth username]"
	}
}

# Modified toolbar item
if {[is_modified] && [cgi auth status] == 1 && [cgi auth username] ne "user"} {
	html eval div class=modified {
		html eval a href=[cgi href changes page $page] "title=Configuration Modified" {
			html tag img src=/img/modified.png
		}
	}
}

if {[cgi mode std]} {
	html eval div class=help_link "title=Toggle Help" {
		html eval a id=help_link href=[cgi href help page $page] {
			html tag img src=/img/help.png
		}
	}
} else {
	html eval div class=help_link {
		html eval div class=help_link_disabled id=help_link {
			html tag img src=/img/help.png
		}
	}
}

# vim: se ts=4:
