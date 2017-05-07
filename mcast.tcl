#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

# NOTE !!!
# the manual command "starcast starcast://switch/3?..." must be issued before script launch
#
lappend auto_path [pwd]
#package require htmlutil
package require Tk

set g_parse(chID) ""
set g_parse(chNum) ""
set g_parse(list) ""    ;#list like {chNum?chID chNum?chID ...}
set g_parse(count) 0    ;#No. of items
set g_ui(pid) 0         ;# process to kill
set g_ui(choice) 0      ;# user selection default to 1st if not found
set g_ui(focusR) 0
set g_curCh(number) 0   ;# for current channel number (invalid)
set g_curCh(idString) "";# authID and sessionID


# as </TAG> parsed, TAG and text are provided
# refer to htmlparse for callback format
# generate list of {chNum?chID chNum?chID ... } as g_parse(list)
proc getTag {tag txt} {
	global g_parse
	switch $tag {
		CAUID {set g_parse(chID) $txt}
		CHANNELNUM {set g_parse(chNum) $txt}
		RELAY {
			if { [string length $g_parse(chID)] && [string length $g_parse(chNum)] } {
				lappend g_parse(list) $g_parse(chNum)?$g_parse(chID)
			}
			set g_parse(chID) ""
			set g_parse(chNum) ""
		}
	}
}


# read file EPG_TABLE.xml for parsing
# ret : 0 - success
#       otherwise - failure
#
proc nReadEPG { } {
	global g_parse
	if { [catch {set epgFile [open EPG_TABLE.xml]} errMsg] } {
		puts "Error !!! $errMsg"
		return -1
	}
	htmlparse [read $epgFile] getTag
	set g_parse(count) [llength $g_parse(list)]
	close $epgFile
	return 0
}


# return channel nr. in starcast.pid if process present
# Out   : g_curCh(number) - 0: fail to find process or starcast.pid doesn't exist
#                           otherwise channel number
#         g_curCh(idString) - "?authID?sessID"
# Ret   : 0 - fail to find pid file or invalid pid
#
proc getCurChannel {} {
	global g_curCh
	if { [catch {set pidFile [open starcast.pid]} errMsg] } { return 0 }
	if { [gets $pidFile line] >= 0 } {               ;#read 1st line from p
		regexp {^[0-9]+} $line pid               ;#pid be leading dititals of "pid?ch"
		if { [catch { exec ps $pid >.cmd } errMsg] } {
			return 0
		} else {
			regexp {[0-9]+$} $line g_curCh(number)    ;#channel be trailing digitals of "pid?ch"
		}
		gets $pidFile g_curCh(idString)
	}
	close $pidFile
	return 1
}


proc btnPress {} {
	global g_ui g_parse g_curCh
	set cmd "\./starcast starcast://switch/[lindex $g_parse(list) $g_ui(choice)]$g_curCh(idString)"
	puts "$cmd"
}


proc setFocus {} {
	focus -force .
	timerOn 1
}


# enable or disable timer
# which schedule 200ms to set focus to get event
proc timerOn {on} {
	global g_ui
	if {$on && [winfo exists .]} {
		set g_ui(pid) [after 200 setFocus]
        } else {
                after cancel $g_ui(pid)
        }
}


proc killAll {} {
	timerOn 0
	destroy .
}


#
# dismiss if in active state
proc keyEnter {} {
	if [string equal active [.right.b cget -state] ] {
		killAll
	}
}


# key right and left binded
# In  : key - Right or Left
#
proc keyLR {key} {
	global g_ui
	if { [set g_ui(focusR) [expr {!$g_ui(focusR)}] ] } {
		.right.b configure -state active
	} else {
		.right.b configure -state normal
	}
}


# key up and down binded
# In  : key -Down or Up
#
proc keyUpDown {key} {
	global g_ui g_parse
	switch $key {
		Down {
			if { $g_ui(choice) == [expr {$g_parse(count)-1}] } {
				set g_ui(choice) 0
			} else { incr g_ui(choice) }
		}
		Up {
			if { $g_ui(choice) == 0 } {
				set g_ui(choice) [expr {$g_parse(count)-1}]
			} else { incr g_ui(choice) -1 }
		}
	}
	btnPress
}


# layout main win
# left & right
# logo at bottom right
proc prepareWin {} {
	wm title . "AVerIPTV Demonstration"
	frame .left ;#.left.0 .left.1 ... are radiobutton of each item 
	frame .right
	pack .left .right -side left -expand yes -padx 10 -pady 10 -fill both

	button .right.b -text "Dismiss" -width 10 \
		-command killAll
	pack .right.b -side top -pady 2 
	image create photo imageLogo -file "logo.gif"
	image create photo shrinkLogo
	shrinkLogo copy imageLogo -shrink -subsample 4 4 
	image delete imageLogo
	label .right.logo -image shrinkLogo
	pack .right.logo -side bottom 

	bind . <Control-c> {killAll}
	bind . <Key-Down> {keyUpDown %K}
	bind . <Key-Up> {keyUpDown %K}
	bind . <Key-Right> {keyLR %K}
	bind . <Key-Left> {keyLR %K}
	bind . <Key-Return> {keyEnter}
	setFocus
}


#
# layout win
# In   - g_parse(list) , items to be displayed
#        g_curCh(number) - channel number found in pid file
proc showWin {refList} {
	upvar $refList items
	global g_ui g_curCh

	prepareWin
	set cmd pack
	for {set i 0} {$i<[llength $items]} {incr i} {
		regexp {([0-9])+} [lindex $items $i] channelNum ;#channelNum be 1 or 4 or ... before '?'
		radiobutton .left.$i -text "Channel $channelNum" -variable g_ui(choice) -value $i \
			-relief flat -command btnPress
		if { $g_curCh(number) == $channelNum } { set g_ui(choice) $i }
		lappend cmd .left.$i
	}

	eval $cmd -side top -expand yes -pady 2 -anchor w
}


proc showErr {msg} {
	prepareWin
	label .left.l1 -text "$msg" -fg red
	pack .left.l1 -side top 
}


#####
# main program
#
if { ![file exists "starcast"] } { showErr "Missing starcast !!!"
} else {
	if { ![getCurChannel] } {		;# get current channel in starcast.pid
		showErr "Find no pid file !!!"
	} else {
		nReadEPG
		if { $g_parse(count) } { 
			showWin g_parse(list)
		} else {
			showErr "Please run starcast in advance !!!"
		}
	}
}


