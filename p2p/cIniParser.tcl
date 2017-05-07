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
	lappend g_pathToInclude $g_progPath
	set g_progPath [file dirname $g_progPath]
}

foreach pp $g_pathToInclude {
	if {[lsearch $::auto_path $pp]<0} {                    ;#add those not yet in path
		if {[catch {glob -type f $pp/*.tcl} msg]} { continue }
		lappend ::auto_path $pp                            ;#and add those contain *.tcl
	}
}


package provide cIniParser 1.0
package require cArray


set DBG_INI	0		;#0 (off) or otherwise (on)

# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbgInit {msg {newline 1}} {
	global DBG_INI
	if { $DBG_INI } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}


itcl::class cIniParser {
	#tuple of (section index)
	#where index is the number allocated for section during m_sectionNumber increment
	private variable m_arraySection

	#ini file name
	private variable m_inFname

	#list of reference to cArray object each for a section
	private variable m_cArrayList

	#number of section found
	private variable m_sectionNumber

	# Init member variable
	constructor { inputFile } {
		set m_inFname $inputFile
		set m_sectionNumber 0
		parse
	}
	
	# Deinit constructor (parse)
	destructor {
		for {set i 0} {$i<$m_sectionNumber} {incr i} {
			itcl::delete object m_cArrayList($i)
		}
	}

	#parse input ini file and construct the data sturcture
	#it works whenever session, key, or value contains blank
	# In  : m_inFname - file name of ini file
	# Out : m_sectionList and m_value
	private method parse {}
	
	#Add a section into class
	# In  : section - section name
	# Out : theArray - the coresponding array retured.
	#       If a new section found, new array object created
	# Ret : the index the section presents in the list
	private method addSection { section }

	#Add a key value into section
	private method addValue { section key value }
	
	#Print parsed structure
	method print {}
	
	#Return a list of section
	# Ret : null list is valid value
	method getSectionList {}

	#Return an array of (key, value) of a section
	# In  : refArray - reference of an array
	# Out : refArray - array updated
	# Ret : number of element in returned array
	method loadSection { section refArray }

	#
	#Return value of given {section, key}
	# In  : section - section name
	#       key - key name
	# Out : refValue - value returned if match
	# Ret : 0 - failed
	#       otherwise - successful
	method getValue { section key refValue }
}


itcl::body cIniParser::addSection { section } {
	if [info exists m_arraySection($section)] {
		dbgInit "Section $section already exists" 0
	} else {
		set m_arraySection($section) $m_sectionNumber
		dbgInit "New section $section created" 0
		cArray m_cArrayList($m_sectionNumber)
		incr m_sectionNumber
	}
	set index $m_arraySection($section)
	dbgInit " which occupies slot\[$index]"
	
	return $index
}


itcl::body cIniParser::addValue { section key value } {
	set index [addSection $section]
	m_cArrayList($index) add $key $value
}


itcl::body cIniParser::parse {} {
	if { [catch {set inFile [open $m_inFname]} errMsg] } {
		puts "No $m_inFname present ..."
		return
	}
	
	set curSection Null
	while { [gets $inFile line] >= 0 } {	                           ;#read each line
		;#remove comments
		regexp {^([^;]*)(;)?} $line match noCmtLine column
		mlib::removeLeadingBlank noCmtLine
		if { ![string length $noCmtLine] } {
			if [string length $column] {
				dbgInit "comment line, $line"
			} else {
				dbgInit "empty line"
			}
			continue
		}
		#here noCmtLine has no leading blank
		if [regexp {^\[([^\]]*)]} $noCmtLine match curSection] {       ;#a session
			set curSection [string trim $curSection]
			if [string length $curSection] {
				addSection $curSection
			} else { puts "null sesstion \"$noCmtLine\""}
		} elseif [regexp {(.+)=(.*)} $noCmtLine match key value] {
			#there is a '=' and key cannot be empty
			set key [string trim $key]
			set value [string trim $value]
			dbgInit "got: $key = \"$value\""
			#key value presents before any section
			addValue $curSection $key $value
		} else {
			dbgInit "ignore line, $line"
		}
	}
	close $inFile
}


itcl::body cIniParser::print {} {
	array set tmpArray {}
	foreach section [array names m_arraySection] {
		set count [loadSection $section tmpArray]
		puts "Section \"$section\" contains $count-elements"
		if { $count } {
			foreach key [array names tmpArray] {
				puts "\t$key = $tmpArray($key)"
			}
		}
		array unset tmpArray
	}
}


itcl::body cIniParser::getSectionList {} {
	if { $m_sectionNumber } {
		return [array names m_arraySection]
	}
	return {}
}


itcl::body cIniParser::loadSection {section refArray} {
	set result 0
	if { $m_sectionNumber } {
		if { [lsearch [array names m_arraySection] $section]>=0 } {
			upvar $refArray Array 
			foreach {key value} [m_cArrayList($m_arraySection($section)) get] {
				set Array($key) $value
				incr result
			}
		}
	}

	return $result
}


itcl::body cIniParser::getValue { section key refValue } {
	if { !$m_sectionNumber } { return 0 }
	set result 0
	if { [lsearch [array names m_arraySection] $section]>=0 } {
		#here section present
		upvar $refValue value          ;#note value is ref twice
		set result [m_cArrayList($m_arraySection($section)) getValue $key value]
	}

	return $result
}

########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cIniParser" } {
	set alist $argv
	set inFile ""
	while { ![mlib::nGetOpt alist {f:d} opt val] } {
		switch $opt {
			f { set inFile $val }
			d { set DBG_INI	1}
		}
	}

	if { ![string length $inFile] } {
		puts "Usage: cIniParser -f INI_FILE"
		exit
	}

	cIniParser ini0 $inFile
	ini0 print

	set sList [ini0 getSectionList]
	puts "There are sections: $sList"
	foreach section $sList {
		set count [ini0 loadSection $section listArray]     ;#store to listArray
		puts "section \[$section]:$count"
		if { $count } {
			parray listArray
			array unset listArray
		}
		puts ""
	}

	variable bufferSize
	if [ini0 getValue Null bufferB bufferSize] {
		puts "===Buffer size = $bufferSize-B"
	}
	itcl::delete object ini0
}
