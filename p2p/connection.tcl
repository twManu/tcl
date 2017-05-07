# Given a time, collect the result of dataShare to get SRC;DEST in connectionhhmm.txt and output the
# mapping of number and directory in mappinghhmm.txt
# Usage: tclsh connection.tcl TIME DATA
#      where TIME is in hh:mm format
#

lappend ::auto_path [pwd]
package require mlib

set g_srcOutput(Relay)	0	;#array of node, output size
set g_firstNLarge       8	;#we calculate the ratio of firstN, 1 based

#
# In  : g_curNumber - the number to assigned to the next node
#       node - instance to check with
#       g_mapping - array like (Relay,n0)
#       g_mapFile - file to record the mapping to
# Out : g_curNumber - updated if added
#       g_mapping - updated if added
proc checkAddMapping {node } {
	global g_mapping g_curNumber g_mapFile g_srcOutput

	if { [lsearch [array names g_mapping] $node]<0 } {
		set g_mapping($node) n$g_curNumber
		set g_srcOutput($node) 0
		puts $g_mapFile "mapping $node to n$g_curNumber"
		incr g_curNumber
	}
}


proc sortAndPrint { outFile } {
	global g_mapping g_srcOutput g_firstNLarge g_curNumber
	set sortList {}

	#####
	#pass one: sort all value in array, sorted index is sortList
	foreach { node output } [array get g_srcOutput] {
		if [set orgCount [llength $sortList]] {
			set i 0
			foreach idx $sortList {
				if { [expr {$output<=$g_srcOutput($idx)} ] } {	;#if cur value smaller, insert in front
					set sortList [linsert $sortList $i $node]
					break
				} else {
					incr i
				}
			}
			if { [expr {$orgCount==[llength $sortList]} ] } {
				set sortList [linsert $sortList end $node]
			}
		} else {
			#empty sortList
			set sortList [list $node]
		}
	}

	set i       0
	set sumN    0
	set sumAll  0
	set startAdd [expr {$g_curNumber - $g_firstNLarge}]
	#####
	#pass two: sum all size of given node
	foreach node $sortList {
		set curSize $g_srcOutput($node)
		incr sumAll $curSize
		if [string equal Relay $node] {
			set relaySize $curSize   ;#relay size
		}
		if { [expr {$i>$startAdd}] } {   ;#add last N
			incr sumN $curSize
		}
		incr i
		puts $outFile "$node/$g_mapping($node) outputs $curSize-bytes"
	}
	puts $outFile "Relay contributes [format %.2f [expr {$relaySize * 100.0 / $sumAll}]]"
	puts $outFile "First $g_firstNLarge nodes contribute [format %.2f [expr {$sumN * 100.0 / $sumAll}]]"
}

#####
# main
#
if { [string length $argv]<2 } {
	puts "Usage: tclsh $argv0 TIME DATA"
	puts "  NOTE: 1. TIME is in hh:mm format"
	puts "        2. connection.txt contains the result and mapping in stdout"
} else {
	set fixedTime [lindex $argv 0]
	set dataFile [lindex $argv 1]
	if { ![regexp $mlib::FMT_HH_MM $fixedTime ] } {
		puts "Wrong time format $fixedTime !!!"
		exit
	}
	if { [catch {set openFile [open $dataFile]} errMsg] } {
		puts "Fail to open file $dataFile !!!"
		exit
	}
	regsub : $fixedTime {} tt	;#time w/o ':'
	if { [catch {set conFile [open connection$tt.txt w]}] } {
		puts "Fail to generate output !!!"
		exit
	}
	if { [catch {set g_mapFile [open mapping$tt.txt w]}] } {
		puts "Fail to generate output !!!"
		exit
	}
	puts "Generate connection in connection$tt.txt and mapping in mapping$tt.txt"
	set g_mapping(Relay) n0		;#Relay occupies node 0
	set g_curNumber 1               ;#the next to be assigned
	set totalSize 0
	set relaySize 0
	
	while { [gets $openFile line] >= 0 } {	;#read each line
		switch -regexp -- $line {
			file= {			;#encounter a directory
				foreach {a b curDir d} [regsub / [regsub -all = $line " "] " "] {
					puts $g_mapFile "Processing $curDir"
					checkAddMapping $curDir
                                }

			}
			default {
				if [regexp $fixedTime $line] {
					foreach {a node size c} $line {
						if [string equal $node Relay] {
							incr relaySize $size
						}
						incr totalSize $size
						checkAddMapping $node
						incr g_srcOutput($node) $size
					}
					puts $conFile "$g_mapping($node);$g_mapping($curDir)"
				}
			}
		}	
	}
	puts $g_mapFile "Share rate =[format %.2f [expr { ($totalSize-$relaySize) * 100.0 /$totalSize}]], $relaySize/$totalSize"
#	foreach { node output } [array get g_srcOutput] {
#		puts $g_mapFile "$node/$g_mapping($node) outputs $g_srcOutput($node)-bytes"
#	}
	sortAndPrint $g_mapFile
	close $g_mapFile
	close $conFile
	close $openFile
}

