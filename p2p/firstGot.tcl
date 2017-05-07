#!/usr/bin/tclsh
# By check DIR/*.log, print if it doen't get 1st packet from Relay
#

lappend ::auto_path [pwd]
package require mlib

set Relay	220.128.100.57

#####
# main
#

foreach ff [glob */*.log] {
	set node [file dirname $ff]
	set inFile [open $ff]
	while { [gets $inFile line] >= 0 } {                            ;#read each line
		if [regexp {packet--} $line] {                          ;#most likely "--Got packet--"
			if [regexp $mlib::FMT_IP $line src] {
				if { ![string equal $src $Relay] } {
					puts "$node get from $src"
				}
				break
			}
		}
	}
	close $inFile
}

