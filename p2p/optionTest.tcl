# tclsh optionTest.tcl ARG_LIST
#
#to make sure all upper path is searched for mlib
#

#search from where we are upto root
set g_progPath [file dirname $argv0]
#the current and known directories must check
set g_pathToInclude "[pwd] C:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4"
while 1 {
	#remove "d:"
	regsub -nocase -- {^[a-z]:} $g_progPath {} tmpPath
	if ![string length tmpPath] {break}
	if { [string equal $tmpPath .] || [string equal $tmpPath /] } {	break }
	#puts $g_progPath
	set g_pathToInclude [concat $g_pathToInclude $g_progPath]
	set g_progPath [file dirname $g_progPath]
}

foreach pp $g_pathToInclude {
	if {[lsearch $::auto_path $pp]<0} {                    ;#add those not yet in path
		if {[catch {glob -type f $pp/*.tcl} msg]} { continue }
		lappend ::auto_path $pp                            ;#and add those contain *.tcl
	}
}

package require mlib

#argument list vs option description
array set g_argList {
	1 "-a51"
	2 "-a51	"
	3 "-a 51"
	4 "-a 51 "
	5 "-a -b51"
	6 "-a -b51	"
	7 "-a -b 51"
	8 "-a -b 51 "
	9 "-a51 -b"
	10 "-a51 -b "
	11 "-a 51 -b"
	12 "-a 51 -b "
	13 "-a51 -b41"
	14 "-a51 -b41 "
	15 "-a51 -b 41"
	16 "-a51 -b 41 "
	17 "-a 51 -b41"
	18 "-a 51 -b41 "
	19 "-a 51 -b 41"
	20 "-a 51 -b 41 "
	21 "-a-b"
	22 "-a -b"
	23 "-a -b "
	24 "ab"
	25 "-c ab"
}

#option descriptions
array set g_descList {
	1 "a:b"
	2 "ab:"
	3 "ab"
	4 "a:b:"
}


proc usage {{msg {}}} {
	global g_argList
	if [string length $msg] { puts stdout $msg }
	puts "Usage: [file tail $::argv0] \[CASE]"
	puts "\t CASE: 1-25 for test string listed below"
	parray g_argList
}


#process arg list against all cases of g_descList
# In  : caseA - index of g_argList
#       arg - argument list to process
proc doCase {caseA arg} {
	global g_descList
	foreach {indexO opt} [array get g_descList] {
		set tmpArg $arg
		puts "case $caseA x $indexO, arg=$arg, opt-desc=$opt"
		while {1} {
			set result [mlib::nGetOpt tmpArg $opt matchOpt value]
			switch $result {
				1 { break }
				\-1 {
					puts "error and terminated"
					break
				}
				0 { puts "found option=$matchOpt, value=$value"	}
			}
		}
	}
}

if [string length $argv] {
	set index [lindex $argv 0]
	if { [info exists g_argList($index)] } {
		doCase $index $g_argList($index)
	} else {
		usage "Case $index doesn't exist"
	}
} else {
	foreach {indexA arg} [array get g_argList] {
		doCase $indexA $arg
	}
}
