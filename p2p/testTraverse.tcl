#
#to make sure all upper path is searched for mlib
#

#search from where we are upto root
set g_progPath [pwd]
#the current and known directories must check
set g_pathToInclude ""
while 1 {
	#remove "d:"
	regsub -nocase -- {^[a-z]:} $g_progPath {} tmpPath
	if ![string length tmpPath] {break}
	if { [string equal $tmpPath .] || [string equal $tmpPath /] } {	break }
	#puts $g_progPath
	#it works when path has blank, say "WM file"
	lappend g_pathToInclude $g_progPath
	set g_progPath [file dirname $g_progPath]
}

foreach pp $g_pathToInclude {
	if {[lsearch $::auto_path $pp]<0} {                    ;#add those not yet in path
		if {[catch {glob -type f $pp/*.tcl} msg]} { continue }
		lappend ::auto_path $pp                            ;#and add those contain *.tcl
	}
}


package require mlib


proc usage {{msg {}}} {
	if [string length $msg] { puts "$msg" }
	puts "Create the same directory structure from the source to the target."
	puts "Usage: testTraverse -s SOURCE_DIR -t TARGET—DIR [-c]"
	puts "         c: check only"
	exit
}


#
# Check whether the parameters are correct
# In  : refSrc, refTgt - reference of source and target directories
# Out : refSrc, refTgt - normalized
proc checkParam {refSrc refTgt} {
	upvar $refSrc src
	upvar $refTgt tgt

	if { ![string length $src] } {
		usage "Missing source directory"
	}
	if { ![string length $tgt] } {
		usage "Missing target directory"
	}
	if { ![file isdirectory $src] } {
		usage "$src is not a directory"
	}
	if { ![file isdirectory $tgt] } {
		usage "$tgt is not a directory"
	}
}

proc callback {level name} {
	global g_srcDir
	global g_tgtDir
	global g_checkOnly

	#puts "$name \($level)"
	regsub $g_srcDir/ $name {} buildDir
	if [file isdirectory $g_tgtDir/$buildDir] {
		if { $g_checkOnly } {
			puts "$g_tgtDir/$buildDir exists...skip"
		}
	} else {
		if { $g_checkOnly } {
			puts "to create $g_tgtDir/$buildDir"
		} else {
			puts "creating $g_tgtDir/$buildDir"
			file mkdir $g_tgtDir/$buildDir
		}
	}
}


########
# main
#
set g_srcDir ""
set g_tgtDir ""
set g_checkOnly 0
set alist $::argv

while { ![mlib::nGetOpt alist {s:t:c} opt val] } {
	switch $opt {
		t { set g_tgtDir [file normalize [lindex $val 0]] }
		s { set g_srcDir [file normalize [lindex $val 0]] }
		c { incr g_checkOnly }
	}
}

checkParam g_srcDir g_tgtDir

mlib::traverseDir $g_srcDir d callback



