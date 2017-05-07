# Process the output file of dataShare.tcl to get the share rate
# Usage: tclsh analyze.tcl INPUTFILE
#

lappend ::auto_path [pwd]
package require mlib 1.0

set g_allReceivedSize 0
set g_allRelaySize 0


#
#
proc parseFile { openFile } {
	global g_allReceivedSize g_allRelaySize
	set totalSize 0
	set relaySize 0
	
	while { [gets $openFile line] >= 0 } {	;#read each line
		if [regexp file= $line] {
			if { $totalSize } {
				set g_allReceivedSize [expr {$g_allReceivedSize+$totalSize }]
				set g_allRelaySize [expr {$g_allRelaySize+$relaySize }]
				puts -nonewline "$client $relaySize $totalSize "
				puts [format %.2f [expr {($totalSize - $relaySize) * 100.0 / $totalSize}]]
			}
			#replace all '=' and '/' with ' '
			#so '===== file=stack1/08192013.log' becomes '     file stack1 08192013.log"
			foreach {a b client d} [regsub / [regsub -all = $line " "] " "] {
			}
			set totalSize 0
			set relaySize 0
		} elseif [regexp ^$mlib::FMT_HH_MM $line] {
			foreach {time src size pkt} $line {
				if [string equal Relay $src] {
					set relaySize [expr $relaySize + $size]
				}
				set totalSize [expr $totalSize + $size]
			}
		}
	}
	if { $totalSize } {
		set g_allReceivedSize [expr {$g_allReceivedSize+$totalSize }]
		set g_allRelaySize [expr {$g_allRelaySize+$relaySize }]
		puts -nonewline "$client $relaySize $totalSize "
		puts [format %.2f [expr {($totalSize - $relaySize) * 100.0 / $totalSize}]]
	}
}


#
# Read input file to generate result
# In  : fname - full name of file path to read data
# Ret : 0 - successful
#       -1 - fail to open file
proc nProcessFile { fname } {
	global g_allReceivedSize g_allRelaySize
	set result -1

	if { [catch {set openFile [open $fname]} errMsg] } {
		puts "Error !!! $errMsg"
	} else {
		parseFile $openFile
		close $openFile
		puts -nonewline "total share rate="
		puts [format %.2f [expr {($g_allReceivedSize - $g_allRelaySize) * 100.0 /$g_allReceivedSize}]]
		set result 0
	}
	return $result
}


#####
# main
#
if {[string length $argv]} {
	set inputFile [lindex $argv 0]
	if {[file isfile $inputFile]} {
		#puts "$inputFile is a file"
		nProcessFile $inputFile
	} else {
		puts "$inputFile is not a file"
	}
} else {
	puts "Please provide input file for analysis"
}
