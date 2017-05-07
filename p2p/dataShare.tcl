# Process a log file and output information shared from one client's view point
# Usage: tclsh dataShare.tcl
#
# NOTE: parameters
#	g_portArray - the Relay's address:port
#	g_time(stop) - "hh:mm:ss" of stop time we examine the log file
#

lappend ::auto_path [pwd]
package require cTimeStr 


set g_parse(timeList) ""	;#for "time src size packetcount"
set g_parse(pktNrList) ""	;#for "nr nr nr" if present
set g_parse(dirList) ""
set g_portArray(220.128.100.57:7844) Relay
set g_parse(start) 1            ;#parse start turn off when g_time(start) set
set g_time(start) ""            ;#data is calculated between start(including) and stop(excluding)
set g_time(stop) ""             ;#time, leave null string if not a constraint

#this mapping from GA to PA when we cannot figure a dir:src mapping
array set g_GAPAmapping {
	220.128.100.60	192.168.3.101
}


#
# 1. Output pktNrList if ever set
# 2. clear curTime and pktNrList
#
# In  : output - 0 : no output pktNrList
#                1 : print pktNrList if ever set
#
proc printAndReset {output} {
	global g_parse

	if {$output} {
		if [string length $g_parse(pktNrList)] {
			set g_parse(timeList) [concat $g_parse(timeList) [lsort -integer $g_parse(pktNrList)]]
		}
		if [string length $g_parse(timeList)] {
			puts $g_parse(timeList)
		}
	}

	set g_parse(timeList) ""
	set g_parse(pktNrList) ""
}


#
# a line contains "print:" inputs, get packet number of parse it
# In  : g_portArray - database of (addr:port, DIRNAME)
proc parseLine { line } {
	global g_parse g_portArray g_GAPAmapping

	if [regexp {SHAREfrom} $line] {
		printAndReset 1
		foreach { rawTime igPnt igShr src size pktCount } "$line" {
			regexp $mlib::FMT_HH_MM $rawTime time
			#try to loop up $g_portArray to find $src
			foreach {addPort dir} [array get g_portArray] {
				if [string equal $addPort $src] {
					set src $dir
					break
				}
			}
			#try to loop up $g_GAPAmapping to find $src behind NAT
			if [regexp $mlib::FMT_IP $src srcGA] {
				#puts "manutest $src is not mapping and GA=$srcGA"
				foreach { GA PA } [array get g_GAPAmapping] {
					if [string equal $GA $srcGA] {
						#the GA:port is replaced by PA:port
						regsub $mlib::FMT_IP $src $PA src
						#try to loop up $g_portArray to find $src again
						foreach {addPort dir} [array get g_portArray] {
							if [string equal $addPort $src] {
								set src $dir
								break
							}
						}
						break
					}
				}
			}
			set g_parse(timeList) "$time $src $size $pktCount"
		}
	} else {	;# a packet number ... #1234
		if [regexp {[0-9]+$} $line number] {
			lappend g_parse(pktNrList) $number
		}
	}
}


#
# For each line
#    if it contains "print:", get source, size, packet count, time
# In  : openFile - opened log file
#
proc parseFile { openFile } {
	global g_parse g_time
	set curTime 0	;#so when no time match in a line, it won't > stopSec

	while { [gets $openFile line] >= 0 } {	;#read each line
		# starting with hh:mm:ss is taken as time
		if [regexp $mlib::FMT_HH_MM_SS $line curTimeString ] {
			cTimeStr tCur $curTimeString
			set curTime [tCur getTimeSec]
			itcl::delete object tCur
			if { !$g_parse(start) && [expr {$curTime>=$g_time(startSec)}] } {
				set g_parse(start) 1
			}
		}
		if { $g_parse(start) } {
			switch -regexp -- $line {
				print: {
 					parseLine $line
				}
				default {
					printAndReset 1
				}
			}
		}
		if { $g_time(stopSec) && [expr {$curTime>=$g_time(stopSec) }] } {
			break                ;#stop processing since time exceeds limit
		}
	}
	set g_parse(start) 0	;#reset flag
	printAndReset 1		;# in case print: is the last line
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

	return $result
}


#
#
proc procDataBaseLine { upperDir logFile openFile } {
	global g_parse g_logArray g_portArray
	variable serverAddr
	set natPort 0

	while { [gets $openFile line] >= 0 } {	;#read each line
		switch -regexp -- $line {
			natserverProc {
				if [regexp $mlib::FMT_IP_PORT $line natServerPort] {
					#extract trailing Ds
					regexp {[0-9]+$} $natServerPort natPort
				}
			}
			serverProc {
				if [regexp $mlib::FMT_IP_PORT $line serverPort] {
					#extract trailing Ds
					regexp {[0-9]+$} $serverPort serverPort
				}
			}
			askTracker: {   ;#occur after serverProc
				if [regexp local $line] {
					regexp $mlib::FMT_IP $line serverAddr
					lappend g_parse(dirList) $upperDir
					set g_logArray($upperDir) $logFile
					set g_portArray($serverAddr:$serverPort) $upperDir
					if { $natPort } {
						set g_portArray($serverAddr:$natPort) $upperDir
					}
				}
			}
			shakehand {
				regexp $mlib::FMT_IP_PORT $line serverPort
				#puts "$serverPort comes from $upperDir"
				set g_portArray($serverPort) $upperDir
			}
		}
	}
}


#
# Checking each directory, we take the first *.log containing "Bringing" as log file and
# get its server port.
#
# Out  : g_logArray(DIRNAME) and g_portArray(DIRNAME) contains log file and addr:port
#        g_parse(dirList) : list of DIRNAME
proc createDataBase { } {
	global g_parse g_logArray g_portArray

	foreach dd [lsort [glob -type d *]] {                                ;#for each dir
		if { [catch {glob -type f $dd/*log} msg] } {         ;#check presence of *log
			continue
		}

		foreach ff [glob -type f $dd/*.log] {
			if { [catch {set openFile [open $ff]} errMsg] } {
				puts $errMsg
				continue
			}
			procDataBaseLine $dd $ff $openFile
			close $openFile
		}
	}
	#record mapping
	foreach dir $g_parse(dirList) {
		foreach {addPort client} [array get g_portArray] {
			if [string equal $dir $client] {
				puts "$dir    $addPort"
			}
		}
	}
}


#####
# main
#

###
# determine start stop time
set g_time(startSec) 0
if [string length $g_time(start)] {
	cTimeStr tStart $g_time(start)
	set g_time(startSec) [tStart getTimeSec]
	itcl::delete object tStart
	#puts "start time = $g_time(start)"
	set g_parse(start) 0
}

set g_time(stopSec) 0
if [string length $g_time(stop)] {
	cTimeStr tStop $g_time(stop)
	set g_time(stopSec) [tStop getTimeSec]
	itcl::delete object tStop
	#puts "stop time = $g_time(stop)"
}


puts "Checking directories ... "
createDataBase

###
# process each file
foreach dd $g_parse(dirList) {
	puts "===== log file=$g_logArray($dd)"
	nProcessFile $g_logArray($dd)
	flush stdout
}
