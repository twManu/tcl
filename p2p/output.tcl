# Given a node (directory), output the hhmm vs Mbps it share w/ others in output_NODE.txt
# Usage: tclsh output.tcl DIR DATA
#

lappend ::auto_path [pwd]
package require mlib

set g_srcOutput(Relay)	0	;#array of node, output size

#
# In  : dir - directory it becomes a source
#       infile - input file contains time src size pkt
# Out : outputs to output_DIR.txt if file create successfully
proc processFile {dir infile} {
	while { [gets $infile line] >= 0 } {                                   ;#read each line
		if [regexp ^$mlib::FMT_HH_MM $line] {                          ;#a line starts from a time
			if { ![info exist curClient] } {
				puts "find no dir before record, $line"
			}
			foreach {time src size pkt} $line {
				if [string equal $src $dir] {                  ;#src is the node we are interested
					if { [lsearch [array names timeSize] $time]<0 } {
						set timeSize($time) 0
						set clientList($time) {}
					}
					incr timeSize($time) $size             ;# "hh:mm"        accumulated-size
					lappend clientList($time) $curClient
				}
			}
		} elseif [regexp file= $line] {                                ;#a line starts a directory
			foreach {a b curClient d} [regsub / [regsub -all = $line " "] " "] {
				#puts $curClient
			}
		}
	}
	if [array exists timeSize] {                                           ;#some record matching requested
		set noSaveFile 0		;#to file by default
		if { [catch {set outFile [open output_$dir.txt w]}] } {
			incr noSaveFile
		}
		foreach tt [lsort [array names timeSize]] {       ;#sort by time
			set szkbps [format %.02f [expr {$timeSize($tt) * 8 / 60 / 1000 /1000.0}]]
			if { $noSaveFile } {
				puts "$tt $szkbps [llength $clientList($tt)] $clientList($tt)"
			} else {
				puts $outFile "$tt $szkbps [llength $clientList($tt)] $clientList($tt)"
			}
		}
		if { !$noSaveFile } { close $outFile }
	} else {
		puts "No output from $dir"
	}
}


#####
# main
#
if { [string length $argv]<2 } {
	puts "Usage: tclsh $argv0 DIR DATA"
	puts "        output to output_DIR.txt"
} else {
	set dir [lindex $argv 0]
	set dataFile [lindex $argv 1]
	if { [catch {set inFile [open $dataFile]} errMsg] } {
		puts "Fail to open file $dataFile !!!"
		exit
	}
	#open input file ok
	processFile $dir $inFile
	close $inFile
}
