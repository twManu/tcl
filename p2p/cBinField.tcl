#
#to make sure all upper path is searched for mlib
#
package provide cBinField 1.0

#search from where we are upto root
set g_progPath [pwd]
#the current and known directories must check
set g_pathToInclude "C:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4 e:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4"
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


package require Itcl


itcl::class cBinField {
	private variable m_name                  ""
	private variable m_value                 0
	private variable m_size
	private variable m_cmd                   ""        ;# used for "binary scan [string range $rawData 20 20] cu m_unknown20
	#cmd "c", "cu", "s", "su"...
	constructor {name cmd} {
		set m_name $name
		set m_cmd $cmd
		#puts "$name $cmd"
		if [regexp {^c} $cmd] {
			set m_size 1
		} elseif [regexp -nocase -- {^s} $cmd] {
			set m_size 2
		} else {
			set m_size 0
		}
	}
	destructor {}
	#In  : refPos - current position
	#Out : refPos - updated position
	method create {data refPos} {
		upvar $refPos nextPos
		set curPos $nextPos
		incr nextPos $m_size
		eval "binary scan \[string range \$data $curPos $nextPos] $m_cmd m_value"
		#puts "$m_name: $m_value"
	}
	method name {} { return $m_name }
	method value {} { return $m_value }
	method valueB {} { return [binary format $m_cmd $m_value] }
	method valueH {} {
		switch -glob $m_cmd {
			c* { return [format "0x%02x" $m_value] }
			s* { return [format "0x%04x" $m_value] }
			S* { return [format "0x%02x02x" [expr $m_value >> 16 ] [expr $m_value % 256]] }
		}
		return " "
	}
	method size {} { return $m_size }
	method setValue {value} {set m_value $value}
}

########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cBinField" } {
	set data "0123456789abcdef"
	#unnamed array to hold fields
	for {set i 0; set curPos 0} {$i<3} {incr i} {
		cBinField array($i) field$i "su"
		array($i) create $data curPos
	}
	for {} {$i<6} {incr i} {
		cBinField array($i) field$i "cu"
		array($i) create $data curPos
	}

	for {set i 0} {$i<6} {incr i} {
		puts "[array($i) name] [array($i) value]"
		itcl::delete object array($i)
	}
}