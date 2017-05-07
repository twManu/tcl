# Process a log file and output information about server response
# Usage: tclsh dataServer.tcl
#

lappend ::auto_path [pwd]
package require cTimeStr 

#
# Parse 'hh:mm:ss' in a string and save in given array
# In:  line - input line
#      refTime - time in sec
# Out: refTime - time in sec updated if match
# Ret: 0 - no time format got
#      1 - g_parse updated
proc getTime { line refTime } {
	upvar $refTime myTime
	set result 0

	if [regexp $mlib::FMT_HH_MM_SS $line rawTime] {
		#puts $rawTime
		cTimeStr t0 $rawTime
		set myTime [t0 getTimeSec]
		itcl::delete object t0
		incr result
	}

	return $result
}


#
# For each line
#    if it contains "print:", get source, size, packet count, time
# In  : openFile - opened log file
#
proc parseFile { openFile } {
	set natTime1 -1
	set trackerTime1 -1
	while { [gets $openFile line] >= 0 } {	;#read each line
		switch -regexp -- $line {
			natserverProc: {
				switch -regexp -- $line {
					SERVENT {
						getTime $line natTime0
					}
					XSTUNT {
						if { $natTime1<0 } {
							getTime $line natTime1
							puts "connect XSTUNT in [expr {$natTime1 - $natTime0}]sec"
						}
					}
				}
			}
			askTracker: {
				if [regexp local $line] {
					getTime $line trackerTime0
				}
			}
			SetChanIDServIP {
				if [regexp {relay=[1-9]+} $line] {
					if { $trackerTime1<0 } {
						getTime $line trackerTime1
						puts "connect Tracker in [expr {$trackerTime1 - $trackerTime0}]sec"
					}
				}
			}
		}
	}
}


#
# Read log file to generate database about share from, packet number, size, time
# In  : fname - full name of file path to read data
# Ret : 0 - successful
#       -1 - fail to open file
#
proc nProcessFile { fname } {
	set result -1
	if { [catch {set openFile [open $fname]} errMsg] } {
		puts "Error !!! $errMsg"
	} else {
		parseFile $openFile
		close $openFile
		set result 0
	}

	return result
}


#####
# main
#
foreach ff [lsort [glob -type f */*.log]] {
	puts [file dirname $ff]
	nProcessFile $ff
}

