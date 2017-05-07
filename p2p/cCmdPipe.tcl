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


package require mlib
package require Itcl
package provide cCmdPipe 1.0

#set DBG_MLIB 1

itcl::class cCmdPipe {
	private variable m_pipe
	private variable m_intervalMS                ;#how often we expiration, d4=5s
	private variable m_cmd
	private variable m_callback                  ;#to process each line. i.e $callback $line
	common m_clockEnd                            ;#when is timeout, m_clockEnd($this)

	# Init member variable string and time value in sec
	constructor { command {periodMS 5000} } {
		set m_cmd $command
		set m_intervalMS $periodMS
		dbg "command $m_cmd"
	}

	method start {durationS {callback {}}}
	method checkTimeOut {}
	method echoLine {}
	
	# demo callback
	proc procLine {line} {
		if [regexp {^S.*} $line] {
			puts "[lindex [info level 0] 0]: $line"
		}
	}
}


itcl::body cCmdPipe::start {durationS {callback {}}} {
	#when to stop
	if [string length $callback] {
		set m_callback $callback
	}

	set m_clockEnd($this) [expr {[clock seconds] + 1000*$durationS}]
	set m_pipe [open "|$m_cmd"]
	fconfigure $m_pipe -blocking 0 -buffering line
	fileevent $m_pipe readable [itcl::code $this echoLine]
	after $m_intervalMS [itcl::code $this checkTimeOut]
	vwait [itcl::scope m_clockEnd($this)]
	
	if { -2==$m_clockEnd($this) } {
		catch {close $m_pipe}
		dbg "timeout: close client"
	} else {
		after cancel [itcl::code $this checkTimeOut]
		dbg "close done in time"
	}
}


itcl::body cCmdPipe::echoLine {} {
	gets $m_pipe line
	if {[eof $m_pipe]} {
		dbg "client finishes"
		set m_clockEnd($this) -1    ;#file ends
		catch {close $m_pipe}
	} elseif {![fblocked $m_pipe]} {
		# Didn't block waiting for end-of-line
		# filter out what we don't want to print
		if [info exists m_callback] {
			$m_callback $line
		} else {
			puts "$line"
		}
	}
}


itcl::body cCmdPipe::checkTimeOut {} {
	set curTime [clock seconds]
	if { $curTime<$m_clockEnd($this) } {
		dbg "time: $curTime"
		after $m_intervalMS [itcl::code $this checkTimeOut]
	} else {
		set m_clockEnd($this) -2    ;#timeout
	}
}




#cCmdPipe::procLine "Start a test"
cCmdPipe pp help
pp start 5 cCmdPipe::procLine
itcl::delete object pp
exit


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cCmdPipe" } {
	set alist $argv
	set cmdLine ""
	set timeOutSEC 0
	while { ![mlib::nGetOpt alist {c:t:} opt val] } {
		switch $opt {
			t { set timeOutSEC $val }
			c { set cmdLine $val }
		}
	}
	if { ![string length $cmdLine] || !$timeOutSEC } {
		puts "Usage:tclsh cCmdPipe.tcl -c COMMAND -t SEC"
		exit
	}
	
	#to avoid get {command}
	cCmdPipe pp [lindex $cmdLine 0]
	pp start $timeOutSEC
	itcl::delete object pp
}
