#library

namespace eval INI {
	variable m_dbg 0
	#NONE line is not [*]
	#EMPTY line is []
	#NORMAL line is [.+]
	array set SESSION {
		NONE         0
		EMPTY        1
		NORMAL       2
	}
	namespace export parse
	namespace export getVal
#
#check if the line is a session declaration
# In  : line - line w/o space
#       prefix - to prefix to session name if parsed
# Out : refSession - if EMPTY : ""
#                    othewise NORMAL, name prefixed
# Ret : SESSION
#
	proc isSession {line refSession prefix} {
		variable m_dbg
		variable SESSION

		upvar $refSession session
		;#match [*]
		if [regexp {^\[([^\]]*)]} $line all session] {
			if [string length $session] {
				set session $prefix$session
				return $SESSION(NORMAL)
			} else {
				set empty Empty
				if {$m_dbg>=1} {
					puts "$empty session"
				}
				
				set session $prefix$empty
				return $SESSION(EMPTY)
			}
		}
		return $SESSION(NONE)
	}

}

#
# In  : fname - normalized file name
#       dbg - debug level
#	      0 disable
#	      1 info message
#	      2 more info message
#	      3 dev message
#       prefix - prefix of array name, say "pp"
# Out : array pp_sec1 (or sec1 if pp is "") created for session "sec1" and so on
# Ret : a list of session name, say "pp_sec1 pp_sec2". i.e arrays created
proc INI::parse {fname {dbg 0} {prefix {}}} {
	variable m_dbg; variable SESSION
	set theList ""
	set m_dbg $dbg

	if {[catch {open $fname} inFile]} {
		puts "fail to open file \"$fname\""
		return $theList
	}
	if [string length $prefix] {
		set curSession $prefix\_Null
		set prefix $prefix\_
	} else {
		set curSession Null
	}
	if {$dbg>=3} {puts "prefix is \"$prefix\""}

	while {[gets $inFile line]>=0} {
		if [regexp {^;} $line] {
			if {$dbg>=2} {puts "comment line \"$line\""}
			continue
		}
		set line [string trim $line]
		if ![string length $line] {
			if {$dbg>=2} {puts "empty line \"$line\""}
			continue
		}
		if [isSession $line session $prefix] {
			if [string length $session] {           ;#could be ""
				set curSession $session
				if {[lsearch $theList $curSession]<0} {
					lappend theList $curSession
					if {$dbg>=2} {puts "session list becomes \"$theList\""}
					set cmd "uplevel 1 { if \!\[info exists \[lindex \{$curSession\}]] \{array set \[lindex \{$curSession\}] \{\}\}}"
					eval $cmd
				}
			}
			continue
		}
		foreach {key val} [split $line =] {
			set key [string trim $key]
			set val [string trim $val]
			if ![string length $key] {
				puts "key is empty"
				continue
			}
			if ![string length $val] {
				if {$dbg>=1} {puts "value is empty"}
			}
			#support Null session
			if {[lsearch $theList $curSession]<0} {
				lappend theList $curSession
				if {$dbg>=2} {puts "session list becomes \"$theList\""}
				set cmd "uplevel 1 { if \!\[info exists \[lindex \{$curSession\}]] \{array set \[lindex \{$curSession\}] \{\}\}}"
				eval $cmd
			}
			if {$dbg>=2} {puts "\"$key\" ===> \"$val\""}
			set cmd "uplevel 1 {set \[lindex \{$curSession\}]\(\[lindex \{$key\}]) \"$val\"}"
			if {$dbg>=3} {puts "$cmd"}
			eval $cmd
		}
	}
	close $inFile
	return $theList
}


#Get value of key with given array name "arrName"
# In  : arrName - name of array
#       key - key to query
# Out : refVal - value updated if key present
# Ret : 1 - success
#       0 - fail
#
proc INI::getVal {arrName key refVal} {
	variable m_dbg

	set cmd "uplevel 1 {\
		foreach {k v} \[array get \[lindex {$arrName}]] { if \[string equal \$k \"$key\"] {set $refVal \$v;return 1} };\
		return 0\
	}"
	if {$m_dbg>=2} {puts $cmd}
	return [eval $cmd]
}

