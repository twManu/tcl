# Process log file in all directories to adjust time by deltaSec which can be minus
# Usage: tclsh adjTime.tcl deltaSec
#

lappend ::auto_path [pwd]
package require cTimeStr 


#
# For each line
#    if it contains "hh:mm:ss", modify and write to log
# In  : openFile - opened log file must be xxx.log
#       writeFile - tmp file to output
#
proc parseFile { openFile writeFile } {
	global g_deltaSec
	set curTimeString 99:99:99              ;#invalid time
	set curReplaceTime 99:99:99             ;#to be replaced

	while { [gets $openFile line] >= 0 } {	;#read each line
		if [regsub $curTimeString $line $curReplaceTime newLine] {    ;#directly replace
			puts $writeFile $newLine
		} elseif [regexp $mlib::FMT_HH_MM_SS $line curTimeString] {   ;#"hh:mm:ss" is taken as time
			cTimeStr tt $curTimeString
			tt setTime [tt sub $g_deltaSec]
			set curReplaceTime [tt getTimeStr]
			itcl::delete object tt
			regsub $curTimeString $line $curReplaceTime newLine
			puts $writeFile $newLine
                } else {
			puts $writeFile $line
		}
        }
}


#
# Read log file to alter the time when it presents "[hh:mm:ss]"
# In  : fname - full name of file path to read data
# Ret : 0 - successful
#       -1 - fail to open file
#
proc nProcessFile { fname } {
	set result -1
	if { [catch {set openFile [open $fname]} errMsg] } {
		puts "Error !!! $errMsg"
	} else {
		if { [catch {set writeFile [open logTmp w]}] } {
			puts "Failed to create tmp file"
			exit
		}
		parseFile $openFile $writeFile
		close $writeFile
		close $openFile
		exec mv logTmp $fname
		set result 0
	}
	return $result
}


#####
# main
#
if { ![string length $argv] } {
	puts "Usage: tclsh $argv0 DELTA_SEC"
	puts "  NOTE: log file in sub-dir will be modified !"
} else {
	set g_deltaSec [expr {[lindex $argv 0] * -1}]       ;#apply for sub
	foreach ff [glob -type f */*.log] {
		nProcessFile $ff
	}
}
