# Process log file in all directories to adjust time by deltaSec which can be minus
# Usage: tclsh adjTime.tcl deltaSec
#
package provide mlib 1.0
set DBG_MLIB	0		;#0 (off) or otherwise (on)

# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbg {msg {newline 1}} {
	global DBG_MLIB
	if { $DBG_MLIB } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}


namespace eval mlib {
#format for regexp, not switch
	variable FMT_HH_MM_SS                     ;#actually 3-part digital
	variable FMT_HH_MM                        ;#actually 2-part digital
	variable FMT_IP
	variable FMT_IP_PORT
	array set m_traverse {}                   ;#refer to traverseDir
	array set m_system {}                     ;#record platform parameters

	namespace export removeLeading0
	namespace export digitalNAddLeading0
	namespace export pathStop
	namespace export getOpt
	namespace export normalizeFname           ;#normalize file name
	namespace export getArrayValue            ;#get caller stack's value by array(name)
#
# Initialize for sys started function
	proc sysInit {} {
		variable m_system
		global DBG_MLIB

		if ![info exists m_system(platform)] {
			array set m_system [array get ::tcl_platform]
			if { $DBG_MLIB } {parray m_system}
		}
	}

	namespace export sysKill
	namespace export traverseDir

#
# generate prefix string before showing a directory name
# In  : m_traverse(level)
# Out : "  +---", "  +-------", ... "  +(3+4x)MINUS"
	proc genDirPrefix {} {
		variable m_traverse
		set prefix ""
		
		for {set i 0} {$i<$m_traverse(level)} {incr i} {
			if $i {
				set prefix "    $prefix"
			} else {
				set prefix "  +---"
			}
		}
		return $prefix
	}
#
# Find all directories from given directory
# In  : m_traverse(level) and is set during first call
#       m_traverse(curDir) always current path
# Out : m_traverse(curDir) adjusted when necessary
	proc goDirs {} {
		variable m_traverse

		if {[catch {glob -type d *} dirs]} {
			#no more directory, one level up
			#regsub {/[^/]+$} $m_traverse(curDir) {} m_traverse(curDir)
			incr m_traverse(level) -1
			cd ..
			dbg "upto [pwd]"
			return
		}
		foreach dd $dirs {
			dbg "now in [pwd] before entering $dd"
			genDirPrefix
			dbg [genDirPrefix] 0
			cd $dd
			incr m_traverse(level)
			set callLevel [expr {$m_traverse(level)+1}]
			dbg "[pwd] \($m_traverse(level))"
			if [string length $m_traverse(callback)] {
				set cmd "uplevel $callLevel {$m_traverse(callback) $m_traverse(level) \"[pwd]\"}"
				dbg "$cmd"
				eval $cmd
			}
			goDirs
		}
		incr m_traverse(level) -1
		cd ..
		dbg "upto [pwd]"
	}

#kill a windows process
#default flag "/F /PID"
	proc windowsKill {pid {opt {}}} {
		if ![string length $opt] {set opt /F}
		catch {exec taskkill $opt /PID $pid}
	}

#kill a unix process
#default flag "-9"
	proc unixKill {pid {opt {}}} {
		if ![string length $opt] {set opt -9}
		catch {exec kill $opt $pid}
	}

	namespace export execGetPid
	proc sysGetPidList {name refList {opt {}}} {
		variable m_system
		set theList ""
	
		sysInit
		set thisProc [lindex [info level 0] 0]
		regsub {^sys} $thisProc $m_system(platform) procName    ;#syskill -> windowskill
		dbg "$procName"
	
		if ![llength [info procs $procName]] {error "$thisProc has no $m_system(platform) version defined"}
		$procName $name $refList $opt
	}

#get pid list under Windows
#
	proc windowsGetPidList {name ref2List {opt {}}} {
		upvar 2 $ref2List theList
		set theList ""
		set pipe [open "|tasklist $opt"]
		set taskStart 0                  ;#starts after =====
		while {[gets $pipe line]>=0} {
			if [regexp ===== $line] {
				incr taskStart
				continue
			}
			if !$taskStart { continue }
			foreach {taskName pid type stage size unit} $line {
				if [string equal $taskName $name] {
					lappend theList $pid
				}
			}
		}
		close $pipe
	}

#get pid list under unix
#
	proc unixGetPidList {name ref2List {opt {}}} {
		upvar 2 $ref2List theList
		set pipe [open "|ps $opt"]
		set taskStart 0                  ;#starts after =====
		while {[gets $pipe line]>=0} {
			if [regexp {PID TTY} $line] {
				incr taskStart
				continue
			}
			if !$taskStart { continue }
			foreach {PID TTY TIME CMD} $line {
				if [string equal $CMD $name] {
					lappend theList $PID
				}
			}
		}
		close $pipe
	}
}

proc mlib::traverseDir {topDir typeList {callback {}}} {
	variable m_traverse

	set m_traverse(topDir)   $topDir 
	set m_traverse(callback) $callback           ;#invoked with cb level directory
	set m_traverse(type)     $typeList           ;#if given type found, callback invoked
	set m_traverse(level)    0                   ;#0-based level during traversal
	set m_traverse(curDir)   $topDir             ;#remember the path

	dbg "$topDir $typeList $callback [string length $m_traverse(callback)]"
	cd $topDir
	goDirs
}

#
# In  : pid - process to be killed
#       opt - option bypass to killPLATFORM, if empty default option is defined by PLATFORM
#
proc mlib::sysKill {pid {opt {}}} {
	variable m_system
	
	sysInit
	set thisProc [lindex [info level 0] 0]
	regsub {^mlib::sys} $thisProc $m_system(platform) procName    ;#syskill -> windowskill
	
	if ![llength [info procs $procName]] {error "$thisProc has no $m_system(platform) version defined"}
	$procName $pid $opt
}


# Execute command and output a list of pid with 'taskName'. The list contains
# new pids generated after command execution. The number of new pid is returned
# In  : refPidList - list of pid
#       taskName - name of task
#       cmd - command to execute
#       opt - option for ps or tasklist
# Out : refPidList - list of pid
# Ret : number of pid found
#
proc mlib::execGetPid {refPidList taskName cmd {opt {}}} {
	upvar $refPidList pidList
	set pidList ""
	set pidCount 0
	
	if [string length $taskName] {
		#preserve origin pids
		sysGetPidList $taskName origPidList $opt

		#exec
		uplevel 1 $cmd

		#update new pids
		sysGetPidList $taskName newPidList $opt

		#comparison and add new
		if [llength $origPidList] {                ;#there were tasks w/ same name
			foreach tt $newPidList {
				if {[lsearch $origPidList $tt]<0} {
					lappend pidList $tt
					incr pidCount
				}
			}
		} else {
			set pidList $newPidList
			set pidCount [llength $pidList]
		}
		#puts "there $pidCount task: $pidList"
	}

	return $pidCount
}


#
# convert \tmp\a to /tmp/a
# In  : fname - file name to convert
#
proc mlib::normalizeFname {fname} {
	set nName [file normalize $fname]
	return $nName
}

#
# return value of array(name)
# The tricky part is use of [lindex {$name}] to preserve name as "bit*(rate+2)"
# In  : arrayName - name of array
#       name - name of (name, value) pair of an array
#
proc mlib::getArrayValue {arrayName name} {
	set cmd "uplevel 1 {set tmpGetArrayValue \$$arrayName\(\[lindex {$name}])}"
	eval $cmd
}


set mlib::FMT_HH_MM                {(\d)+:(\d)+}
set mlib::FMT_HH_MM_SS             {(\d)+:(\d)+:(\d)+}
set mlib::FMT_IP                   {(\d)+\.(\d)+\.(\d+)\.(\d)+}
set mlib::FMT_IP_PORT              {(\d)+\.(\d)+\.(\d)+\.(\d)+:(\d)+}


#try to modify str if it starts with 0
#conver "01" to 1, "00" to 0, "00032" to 32
# In  : refStr - reference to value
# Out : refStr - modified
proc mlib::removeLeading0 {refStr} {
	upvar $refStr str

	if { [string length $str] } {
		if { [regsub {^0+} $str {} str] } {
			#avoid subst leading 0's to null
			if {![string length $str]} {
				set str 0
			}
		}
	}
}


# convert number to n_digitals, say 1 to 01 if n_digital=2
# In  : refNumber - reference to number
#       n_digitals - number of digitals the output should be
# Out : altered refNumber
# Ret : <0 - input value < 0 and not altered
proc mlib::digitalNAddLeading0 { refNumber n_digitals } {
	upvar $refNumber number

	if { $number>=0 } {
		regsub $n_digitals $n_digitals {0&d} fmt    ;#replace 3 as 03d
		set number [format %$fmt $number]
	}
	return $number
}


#check if given path is "/", ".", or "d:/"
# In  : path - path to check with
# Out : 1 - no more parent to check with
#       0 - otherwise
proc mlib::pathStop {path} {
	if { [string length $path] } {
		if { ![string equal $path .] } {         ;#not '.'
			if { ![regexp -nocase -- {^([a-z]:)?/$} $path] } {
				#not "a:/" nor '/'
				return 0
			}
		}
	}
	return 1
}


proc mlib::removeLeadingBlank refString {
	upvar $refString theString
	if [string length $theString] {
		regsub {^[\s|\t]*} $theString {} theString
	}
}
		
set g_optionList ""
#
# each call return and option and value if match
# option description is "d:abc" where : means a value following the option
# In  : refAlist - ref to argument list variable
#       optlist - option description
#       refOpt - ref to option variable
#       refVal - ref to value variable for parsed option
# Out : refAlist, refOpt, and refVal updated
# Ret : 0 - success
#       1 - no more argument to parse
#       -1 - invalid option encountered
proc mlib::nGetOpt {refAlist optList refOpt refVal} {
	global g_optionList g_option
	upvar $refAlist alist
	upvar $refOpt opt
	upvar $refVal val

	#removeLeadingBlank alist
	set alist [string trim $alist]
	if { ![string length $alist] } {return 1}                          ;#nothing to do
	if { ![string length $optList] } {return 1}

	if { ![string equal $optList $g_optionList] } {
		set g_optionList $optList
		dbg "option list=\"$optList\""
	##
	# 1. build (opt, has-value) by option description
	#
		#match 'x' or "x:" each iteration
		foreach {optAll curOpt column} [regexp -all -inline -- {(.)(:)?} $optList] {
			if [string equal $curOpt :] {
				dbg "wrong option ':'"
				return -1
			}
			if {[string length $column]} {
				set g_option($curOpt) 1
				dbg "$curOpt has value"
			} else {
				set g_option($curOpt) 0
				dbg "$curOpt has no value"

			}
		}
	}

	##
	# 2. check refAlist w/ first item based on option
	#
	foreach {optAll dash opt val rest} [regexp -inline -- {(-)([ |\t]*.)([^-]*)(.*)} $alist] {
		set opt [string trim $opt]                                 ;#there might be leading blank
		set val [string trim $val]                                 ;#val might be all blank
		dbg "opt=$opt, value=$val, rest=$rest"
		if { [info exists g_option($opt)] } {
			if {$g_option($opt)} {
				#need a value
				if [string length $val] {
					dbg "option '$opt' = $val"         ;#successful
				} else {
					dbg "option '$opt' missing value"
					return -1    
				}
			} else {
				#need no value
				if [string length $val] {
					dbg "option '$opt' needs no value"
					return -1
				}
				dbg "option '$opt'"                        ;#successful
			}
		} else {
			dbg "option '$opt' not defined"
			return -1
		}

		set alist $rest
		return 0
	}
	dbg "Fail to find an option"
	return -1
}


