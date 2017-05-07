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

package require cGit

proc usage {{msg {}}} {
	if [string length $msg] { puts stdout $msg }
	puts "Usage: [file tail $::argv0] \[-i IP]"
	puts "\t -i: IP xx.xx.xx.xx must be provided for replacement"
	puts "\t     if not present, current configure is displayed"
}


# ###
# main
#
set alist $argv
set g_inputIP ""
while { ![mlib::nGetOpt alist {i:h} opt val] } {
	switch $opt {
		i { set g_inputIP $val }
		default {
			usage "wrong option $opt"
			exit
		}
	}
}


cGit g_gitObj [pwd] $g_inputIP
set port [g_gitObj getPort]
puts "Git repository is [g_gitObj getGitRoot]"
puts "Git source = [g_gitObj getOldIP]:$port"
if [string length $g_inputIP] {
	puts "\t ...to be replaced w/ [g_gitObj getNewIP]:$port"
	g_gitObj replaceIP
}

itcl::delete object g_gitObj
