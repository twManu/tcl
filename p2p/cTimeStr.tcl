#
#to make sure all upper path is searched for mlib
#
package provide cTimeStr 1.0

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


set TIME_SEC_MAX         86400

itcl::class cTimeStr {
	private variable m_timeSec 
	private variable m_timeStr

	# Init member variable string and time value in sec
	constructor { timeString } {
		if { ![setTime $timeString] } {
			set m_timeSec -1
			set m_timeStr 00:00:00
		}
	}

	#get private variable
	method getTimeSec {}
	method getTimeStr {}

	# In  : timeString - HH:MM or HH:MM:SS formatted
	# Out : m_timeSec - update if correct string format
	#                 - -1 if wrong format
	#       m_timeStr - update HH:MM:SS if correct format
	# Ret : 0 - failed (format wrong)
	#       1 - success
	method setTime { timeString }

	#Return our time minus given time
	# In  : sec - if a time string HH:MM(:SS) provided it is substracted after converting to sec
	#           - if all digital (- allowed), substraction    
	# Ret : 86400 - wrong result
	#	otherwise - time in sec substracted
	method sub { sec }

	#Turn 59204 to 16:26:44 (hh:mm:ss)
	# In  : sec - second to transform
	# Ret : formated "hh:mm:ss"
	#       24:60:60 means input error
	protected method secToTimeString { sec }
}


itcl::body cTimeStr::getTimeSec {} {
	return $m_timeSec
}


itcl::body cTimeStr::getTimeStr {} {
	return $m_timeStr
}


itcl::body cTimeStr::secToTimeString { sec } {
	global TIME_SEC_MAX
	if [$sec>=$TIME_SEC_MAX] {
		set hh 24
		set mm 60
		set ss 60
	} else {
		set hh [expr {$sec / 3600} ]
		set sec [expr {$sec - $hh*3600} ]   ;#sec substract hour part
		set mm [expr {$sec / 60} ]
		set ss [expr {$sec - $mm*60} ]      ;#sec substract min part
		mlib::digitalNAddLeading0 hh 2
		mlib::digitalNAddLeading0 mm 2
		mlib::digitalNAddLeading0 ss 2
	}

	return [join "$hh $mm $ss" :]
}


itcl::body cTimeStr::setTime { timeString } {
	if [regexp {(\d+):(\d+)(:\d+)?} $timeString m_timeStr hh mm ss] {   ;#match two forms w/ or w/o ss
		if { ![string length $ss] } {
			set m_timeStr $m_timeStr:00                         ;#fail to match 3 seg, append ":00"
			set ss 0
		} else {
			regsub {:0*} $ss {} ss                              ;#remove :0 or :00
			if { ![string length $ss] } {
				set ss 0                                    ;#avoid null
			}
		}
		mlib::removeLeading0 hh
		mlib::removeLeading0 mm
		#puts "hh=$hh, mm=$mm, ss=$ss"

		if { $ss>59 || $mm>59 || $hh>23 } {
			puts "time too large !!"
			return
		}
	
		set m_timeSec [expr {$hh * 3600 + $mm * 60 + $ss}]
		#puts $m_timeStr\($m_timeSec)
		return 1
	} else {
		if { [regexp {^\d+} $timeString matchSec] } {
			#starts with a digital
			if { [string equal $timeString $matchSec] } {
				#all digital
				set m_timeSec $timeString
				set m_timeStr [secToTimeString $m_timeSec]
				return 1
			}
		}
	}

	return 0
}


itcl::body cTimeStr::sub { sec } {
	global TIME_SEC_MAX
	if { ![string length $sec] } {return $m_timeSec}      ;#mull do nothing
	if [regexp $mlib::FMT_HH_MM $sec] {
		cTimeStr t0 $sec
		set sec [t0 getTimeSec]
		itcl::delete object t0
	} else {
		regexp {^(-)?(\d+)} $sec match sign unsignedSec
		if { ![string length $unsignedSec] } {
			puts "time has no digits"
			return $TIME_SEC_MAX                  ;#error
		}
		if [string length $sign] {                    ;#tmp use of unsignedSec for compare
			set unsignedSec $sign$unsignedSec
		}
		if { ![string equal $sec $unsignedSec] } {
			return $TIME_SEC_MAX                  ;#not all digit
		}
	}

	set result [expr {$m_timeSec - $sec}]                 ;#sub
	if { $result<0 } {                                    ;#adjust
		incr result $TIME_SEC_MAX
	} elseif { $result>=$TIME_SEC_MAX } {
		set result [expr {$result - $TIME_SEC_MAX}]
	}

	return $result
}


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cTimeStr" } {
	set alist $argv
	set theTimeStr ""
	while { ![mlib::nGetOpt alist {t:} opt val] } {
		switch $opt {
			t { set theTimeStr $val }
		}
	}
	if { ![string length $theTimeStr] } {
		puts "Usage:tclsh cTimeStr.tcl -t HH:MM\[:SS]"
		exit
	}
	
	cTimeStr t0 $theTimeStr
	puts "[t0 getTimeStr] evaluate to [t0 getTimeSec]s"
	puts [t0 sub 4]
	puts [t0 sub -4]
	puts [t0 sub 00:01:01]
	puts [t0 sub 23:59:59]
	itcl::delete object t0
}
