# htmlutil.tcl - by Jean-Claude Wippler, September 2001
# exec with "tclsh htmlutil.tcl

package provide htmlutil 0.1

# parse HTML text, setting array elements along the way
# callback - a proc name of calling procedure
#		invoked when a tag end encountered
#		the format is "callback tag text"
#            a "" is treated as null callback
proc htmlparse {text callback {aref html} {ignorecase 1}} {
	upvar $aref avar
	set avar() ""

	regsub -all {<!--.*?-->} $text {} text ;#remove comments
	append text </>

	set tags ""
	set hist ""
	foreach {a b c} [regexp -all -inline {(.*?)<(.*?)>} $text ] {
		#manutest b is <text>
		#puts "a=$a, b=$b, c=$c"
		set avar(<text>) $b
		set d ""
		regexp {^(\w+)\s(.*)} $c - c d
		if {$ignorecase} {set c [string toupper $c]}
		if {[regexp {^/(.*)} $c - e]} {
			#manutest looks a "/" found
			set t "/"
			while {[llength $tags]} {
				set t [lindex $tags end]
				set avar(/$t) [lindex $hist end]
				set tags [lreplace $tags end end]
				set hist [lreplace $hist end end]
				if {[string equal $t $e]} break
			}
			if [string length $callback] {
#fails if text is " MEMBER EXIST"				uplevel "$callback $t $avar(<text>)"
					set cmd [list $callback $t $avar(<text>)]
					uplevel $cmd
			}
	        # comment out line below to ignore unbalanced closing tags
        	#if {![string equal $t $e]} { set avar($c) {} }
		} else {
			set avar($c) $d
			lappend tags $c
			lappend hist $d
		}
	}	; #foreach
}

########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if {[file root [file tail $argv0]] == "htmlutil"} {
	proc show {r e op} {
		upvar $r a
		puts [list set html($e) $a($e)]
	}
	trace var html w show
	set in {a<b c>d<e f>g<e h>i</e>j</e>k<e l>m</b>n</o>p}
	puts "Parsing: $in"
	puts [htmlparse $in ""]
}

