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


package provide cCCommentParser 1.0
package require Itcl


set DBG_CCMT	1		;#0 (off) or otherwise (on)

# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbgCCMT {msg {newline 1}} {
	global DBG_CCMT
	if { $DBG_CCMT } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}




itcl::class cCCommentParser {
	public variable eCCOMMENT_ERR
	public variable eCCOMMENT_NONE
	public variable eCCOMMENT_FRONT
	public variable eCCOMMENT_REAR

	#parse result
	private variable m_parseResult

	#in mult-comment 
	private variable m_inComment

	#curent line
	private variable m_line

	#input file stream
	private variable m_inFile

	# Init member variable
	# input file is an opened stream and not checked
	constructor { inputFile } {
		set m_line ""
		set m_inFile $inputFile
		set m_inComment 0
		set eCCOMMENT_NONE 0
		set eCCOMMENT_ERR -1
		set eCCOMMENT_FRONT 1
		set eCCOMMENT_REAR 2
		set m_parseResult $eCCOMMENT_NONE
	}
	
	# Deinit constructor (parse)
	destructor {
	}

	# get index of '/' of first "/*" ($forStart)
	# or
	# get index of '/' of first "*/" (!$forStart) in str
	# Ret : -1 - no match of the pattern
	#       otherwise - index of "/" of the pattern
	private method getSlashLocOfCMT {str forStart}

	# To determine whether this line is multi-line comment open
	# and return valid data/comment in this line
	# NOTE: it can not deal with case "//" found before "/*"
	#
	# In  : str - string to check with
	#       refData - caller should init it with "" on first call
	#       refComment - caller should init it with "" on first call
	# Out : refData - valid data concatenated
	#       refComment - comment concatenated
	# Ret : 0 - multi-line comment closed, including no comment
	#       1 - multi-line comment open
	private method multiCMTOpen {str refData refComment}

	# To determine whether this line is single line comment,
	# multi-line comment, or multi-line comment open.
	# And return valid data/comment in this line
	#
	# In  : str - string to check with
	#       refData - caller should init it with "" on first call
	#       refComment - caller should init it with "" on first call
	# Out : refData - valid data concatenated
	#       refComment - comment concatenated
	# Ret : 0 - multi-line comment closed, including no comment
	#       1 - multi-line comment open
	private method locateCMT {str refData refComment}

	#read a line and then parse input
	# In  : m_inFile
	# Out : m_state update
	# Ret : < 0 - EOF or error
	method parse {refData refCMT {refLine ""}}
}


itcl::body cCCommentParser::getSlashLocOfCMT {str forStart} {
	set loc -1
	if {$forStart} {
		if [regexp -indices -- {/\*} $str index] {
			foreach {loc tmp} $index { }
		}
	} else {
		if [regexp -indices -- {\*/} $str index] {
			foreach {tmp loc} $index { }
		}
	}

	return $loc
}


itcl::body cCCommentParser::multiCMTOpen {str refData refComment} {
	upvar $refData data
	upvar $refComment comment

	#to match 1st "/*"
	if [regexp {/\*(.*)} $str all remainStr] {
		#set data before "/*"
		set startComment1 [getSlashLocOfCMT $str 1]
		if { $startComment1 } {
			#leading data append to original data
			set data "$data[string range $str 0 [expr {$startComment1-1}]]"
		}

		#to match 1st "*/" in remaining string
		if [regexp {\*/(.*)} $remainStr all trailing] {
			#set comment before "*/", then check the rest
			set comment "$comment/\*[string range $remainStr 0 [getSlashLocOfCMT $remainStr 0]]"
			return [locateCMT $trailing data comment]
		}
		#no "*/" found
		set comment "$comment[string range $str $startComment1 end]"
		return 1
	}
	#no "/*" found
	set data "$data$str"
	return 0
}


# To determine whether this line is single line comment,
# multi-line comment, or multi-line comment open.
# And return valid data/comment in this line
#
# In  : str - string to check with
#       refData - caller should init it with "" on first call
#       refComment - caller should init it with "" on first call
# Out : refData - valid data concatenated
#       refComment - comment concatenated
# Ret : 0 - multi-line comment closed, including no comment
#       1 - multi-line comment open
itcl::body cCCommentParser::locateCMT {str refData refComment} {
	upvar $refData data
	upvar $refComment comment

	#to match 1st "/" with trailing string
	if [regexp {([^/]*)/(.+)} $str all b4Slash remainStr] {
		switch [string index $remainStr 0] {
			* {               #"/*" found first
				return [multiCMTOpen $str data comment]
			}
			/ {               #"//" found first
				set data "$data$b4Slash"
				set comment "$comment/$remainStr"
				return 0
			}
			default {         #a "/" before maybe "//" and/or "/*"
				set data "$data$b4Slash/"
				return [locateCMT $remainStr data comment]
			}
		}
	}
	#no "/.+" found
	set data "$data$str"
	return 0
}


itcl::body cCCommentParser::parse {refData refCMT {refLine ""}} {
	upvar $refData data
	upvar $refCMT comment

	if { $m_parseResult<$eCCOMMENT_NONE } {
		return $m_parseResult	;#no more read once EOF
	}
	set m_parseResult [gets $m_inFile m_line]
	if { $m_parseResult<$eCCOMMENT_NONE } {
		return $m_parseResult
	}

	if [string length $refLine ] {
		#copy line
		upvar $refLine usrLine
		set usrLine $m_line
	}

	set data ""
	if { $m_inComment } {
		#during multi-line comment, "*/" first
		if [regexp {\*/(.*)} $m_line all remainStr] {
			#found "*/", collect comment
			set comment [string range $m_line 0 [getSlashLocOfCMT $m_line 0]]
			set m_inComment [locateCMT $remainStr data comment]
		} else {
			#whole line comment
			set comment $m_line
		}
	} else {
		set comment ""
		set m_inComment [locateCMT $m_line data comment]
	}
	return $m_parseResult
}


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cCCommentParser" } {
	set alist $argv
	set inFile ""
	while { ![mlib::nGetOpt alist {f:} opt val] } {
		switch $opt {
			f { set inFile $val }
		}
	}

	if { ![string length $inFile] } {
		puts "Usage: cCCommentParser -f FILE"
		exit
	}
	#todo catch
	set inStream [open $inFile]

	cCCommentParser c0 $inStream
	set lineNr 1
	while { [c0 parse data comment line]>=0 } {
		puts "$line"
		puts "  line$lineNr, data=\"$data\", comment=\"$comment\""
		incr lineNr
	}
	itcl::delete object c0
	close $inStream
}

