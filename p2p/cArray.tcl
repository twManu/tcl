#
#to make sure all upper path is searched for mlib
#

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

package require Itcl
package provide cArray 1.0

set DBG_INI	0		;#0 (off) or otherwise (on)

# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbg {msg {newline 1}} {
	global DBG_INI
	if { $DBG_INI } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}

#####
#A class wrapper of array so that one can create and delete object
#
itcl::class cArray {
	private variable m_array
	private variable m_count
	private variable m_context

	# Init member variable
	# In  : context - the context to initialize with (defaults to null list)
	#                 it's by implementation instead of class
	constructor { {context {}} } {
		set m_count 0
		array set m_array {}
		set m_context $context
	}

	method print {} {
		parray m_array
	}

	#Assign (key, value) to array
	# In  : m_inFname - file name of ini file
	# Out : m_sectionList and m_value
	method add {key value} {
		set m_array($key) $value
		incr m_count
	}
	
	#Get name list
	# Ret : name list returned, if no element, {} returned
	method names {} {
		if { $m_count } {
			return [array names m_array]
		}
		return {}
	}
	
	#Get key, value list
	# Ret : List of value pair returned, if no element {} returned
	method get {} {
		if { $m_count } {
			return [array get m_array]
		}
		return {}
	}
	
	#Reset array
	# In  : context - the context to initialize
	#                 if not present, old context keeps
	method reset { {context {}} } {
		array unset m_array
		set m_count 0
		if [strlen $context] {
			set m_context $context
		}
	}
	
	#Get context
	# Ret : context set during constructor or reset
	method getContext {} {
		return $m_context
	}
	
	#Get number of elements
	method getNumberOfElement {} {
		return $m_count
	}

	#Get value of given key
	# In  : key - key name to query
	# Out : refValue - updated if key present
	# Ret : 0 - failed
	#       otherwise - successful
	method getValue {key refValue} {
		set result 0
		if { $m_count } {
			if { [lsearch [array names m_array] $key]>= 0 } {
				upvar $refValue value
				incr result
				set value $m_array($key)
			}
		}
		return $result
	}
}

########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cArray" } {
	set i 1
	cArray a$i
	a$i add key1 value1
	a$i add key2 value2
	a$i add key3 value3
	puts "array[a$i getContext] [a$i names]"
	puts "[a$i get]"
	a$i print
	itcl::delete object a$i

	incr i                   ;#two dimension array

	cArray a$i $i
	a$i add key11 value11
	a$i add key12 value12
	a$i add key13 value13
	puts "array[a$i getContext] [a$i names]"
	puts "[a$i get]"

	itcl::delete object a$i
}