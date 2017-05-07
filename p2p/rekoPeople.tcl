#
#to make sure all upper path is searched for mlib
#

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
package require mlib


set DBG_RK	0		;#0 (off) or otherwise (on)

# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbgRK {msg {newline 1}} {
	global DBG_RK
	if { $DBG_RK } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}




itcl::class cRkMan {
	#constant
	private variable OFFSET_MAN          [expr 0x1100]          ;#first man file offset
	private variable SZ_NAME             6                      ;#name at 0
	private variable CHARM_AFTER_NAME    11
	private variable SZ_CFW              4                      ;#read the last byte?
	#private SIZE_PER_MAN	    21
	private variable NR_PEOPLE           384
	#field name and channel
	private variable m_file


	#people index by name, having value "charm, force, wisdom"
	private variable m_people

	# Init
	constructor { inFile } {
		array set m_people {}
		#inFile is a list so we need to "lindex" in advance
		set m_file(name) [file normalize [lindex $inFile 0]]
		set m_file(channel) 0
	}

	# Deinit constructor (parse)
	destructor {
		if { $m_file(channel)!=0 } {
			close $m_file(channel)
			set m_file(channel) 0
			set m_file(name) ""
		}
	}

	# start processing
	method parse {}
	
	# field
	# 0 : charm
	# 1 : force
	# 2 : widsom
	method sort { field {count 15} }
}

#
# field: The field to compare with
# count: Number of people printed
itcl::body cRkMan::sort { field {count 15} } {
	array set fieldName {
		0      "     (c)  f  w  sum"
		1      "       c  (f)  w  sum"
		2      "       c  f  (w) sum"
		3      "      c   f  w  (sum)"
	}

	if { $field<0 || $field>[array size fieldName] } {
		puts "Invalid field $field"
		exit
	}

	puts "$fieldName($field)"
	set nameValue {}
	incr field
	
	foreach {name value} [array get m_people] {
		lappend nameValue [linsert $value 0 $name]
	}
	set i 0
	foreach {element} [lsort -integer -decreasing -index $field $nameValue] {
		if { $i>=$count } { break }
		puts "$element"
		incr i
	}
}


itcl::body cRkMan::parse {} {
	#todo normalize
	if { [catch {set m_file(channel) [open $m_file(name)]} msg] } {
		puts "Fail to open $m_file(name)]"
		exit
	}

	fconfigure $m_file(channel) -translation binary
	chan seek $m_file(channel) $OFFSET_MAN start

	for {set i 0} {$i<$NR_PEOPLE} {incr i} {
	##byte by byte, correct in output
	#for {set i 0} {$i<$SIZE_PER_MAN} {incr i} {
	#	set rawData [read $g_file(channel) 1]
	#	binary scan $rawData H2 hexData
	#	puts "$hexData"
	#}
	
	##$OFFSET_MAN bytes at once, correct in output
	#set rawData [read $g_file(channel) $OFFSET_MAN]
	#binary scan $rawData H42 hexData
	#puts "$hexData"

		set rawData [read $m_file(channel) $SZ_NAME]
		set name [encoding convertfrom big5 $rawData]
		#detecting "???"
		binary scan $rawData H12 nameInHex

		chan seek $m_file(channel) $CHARM_AFTER_NAME current
		set rawData [read $m_file(channel) 4]
		binary scan [string range $rawData 0 0] c charm
		binary scan [string range $rawData 1 1] c force
		binary scan [string range $rawData 2 2] c wisdom
		set sum [expr {$charm+$force+$wisdom}]
		if [string equal $nameInHex a148a148a148] {
			dbgRK "Ignore $name"
		} elseif { [lsearch [array names m_people] $name]<0 } {
			set m_people($name) "$charm $force $wisdom $sum"
			dbgRK "$name:  $charm  $force  $wisdom"
		} else {
			dbgRK "Duplicate $name"
		}
	}
}


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "rekoPeople" } {
	set alist $argv
	set fileName ""
	set sortIndex 0
	set count 20
	while { ![mlib::nGetOpt alist {f:s:c:} opt val] } {
		switch $opt {
			f { set fileName $val }
			s { set sortIndex $val }
			c { set count $val }
		}
	}

	if { ![string length $fileName] } {
		puts "Usage: rekoPeople -f FILE -s INDEX -c COUNT"
		puts "   INDEX:"
		puts "      0 - charm"
		puts "      1 - force"
		puts "      2 - wisdom"
		puts "      3 - sum of the three"
		exit
	}
	
	cRkMan db $fileName
	db parse
	db sort $sortIndex $count
	itcl::delete object db
}

