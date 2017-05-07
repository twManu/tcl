#
# cksum.tcl -s FILE_OF_SUM

#search from where we are upto root
set g_progPath [file dirname $argv0]
#the current and known directories must check
set g_pathToInclude "[pwd] C:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4 e:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4"
while 1 {
	#remove "d:"
	regsub -nocase -- {^[a-z]:} $g_progPath {} tmpPath
	if ![string length tmpPath] {break}
	if { [string equal $tmpPath .] || [string equal $tmpPath /] } {	break }
	#puts $g_progPath
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
package require Itcl

proc usage {{msg {}} {newline 1}} {
        if [string length $msg] {
        	if { $newline } {
                	puts "$msg"
                } else {
                        puts -nonewline "$msg"
        	}
        }
        puts "Usage: tclsh cksum.tcl -s FILE_OF_SUM"
        puts "       -s : file contains checksum"
        exit
}


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cksum" } {
	set sumFile ""
	set alist $argv
	while { ![mlib::nGetOpt alist {s:} opt val] } {
		switch $opt {
			s { set sumFile $val }
                        default { usage "Unknown parameter !!!"}
		}
	}

        # check param
        if ![string length $sumFile] {
                usage "Missing input file"
        }
        if { [catch {open $sumFile} sumFd] } {
                usage "Could not open $sumFile"
        }

        #process each file line by line
        while { [gets $sumFd line] >= 0 } {
                foreach {sum fname} $line {
                        #"md5sum -c test*" under Win generates a leading * for each file
                        regsub {\*} $fname {} fname
                        #puts "sum=$sum, name=$fname"
        		#exec md5sum $fname >
                        if ![file exists $fname] {
                                puts "   Cannot file $fname...skip"
                                continue
                        }
                	set fl [open "|md5sum $fname"]
                        set result [lindex [read $fl] 0]
                        if [string equal $result $sum] {
                                puts "$fname OK"
                        } else {
                                puts "$fname mismatch !!!"
                        }
                        close $fl
		}
	}

        close $sumFd
}






