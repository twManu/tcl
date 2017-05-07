source INI.tcl

set win_Null(manutest1)	shouldExist
set [lindex {win_MCI Extensions.BAK}](manutest1) mustExist
set win_Null(test1) shouldntBeThis

if { $::argc<1 } {
	puts "Usage: tclsh iniTest.tcl INI_FILE"
	exit 1
}

#c:/Users/manuchen/win.ini
set fname [file normalize [lindex $::argv 0]]
#win
set prefix [file tail [file rootname $fname]]
set lst [INI::parse $fname 0 $prefix]
puts "[string repeat - 40] demo#1 [string repeat - 40]"
foreach ss $lst {
	set kvPair [array get $ss]
	#access indirectly so that ss and nn can contain space
	if [llength $kvPair] {
		#parray $ss
		foreach {k v} $kvPair {	puts "$ss\($k)=$v" }
	} else {
		puts "empty session \"$ss \""
	}
}

puts "\n[string repeat - 40] demo#2 [string repeat - 40]"
foreach ss $lst {
	foreach nn [array names $ss] {
		if [INI::getVal $ss $nn value] {
			puts "$ss\($nn) = $value"
		} else {
			puts "fail to access $ss\($nn)"
		}
	}	
}

#puts "$val"
exit
