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


package require mlib
package require Itcl
package provide cGit 1.0

set g_fileList {
	.git/config
	.git/FETCH_HEAD
	.git/logs/HEAD
	.git/logs/refs/heads/master
}

itcl::class cGit {
	private variable m_gitRoot        ""
	private variable m_inputPath      ""
	private variable m_oldIP          ""
	private variable m_newIP          ""
	private variable m_port           0

	#
	# Given path and newIP to set with
	# In  : path - full path or relative path of (subdir of)git repository
	#       newIP - new IP to replace with, no replace if not present
	constructor {path {newIP {}}} {
		if [string length $newIP] {
			regexp $mlib::FMT_IP $newIP m_newIP
		}
		set m_inputPath $path
		getOrigIP
	}
	
	#
	# Get original IP and port by locating .git in parent directory and upwards
	# In  : m_inputPath - the sub-directory from which we tried to locate git repository upwards
	# Out : m_oldIP, m_port and m_gitRoot updated if successful
	# Ret : 0 - fail to locate git repository nor parse server IP
	#       1 - successful
	protected method getOrigIP {}
	method getOldIP {}                { return $m_oldIP }
	method getNewIP {}                { return $m_newIP }
	method getPort {}                 { return $m_port }
	method getGitRoot {}              { return $m_gitRoot }
	method replaceIP {}
}



itcl::body cGit::getOrigIP {} {
	set curPath $m_inputPath
	#find upwards until .git/config present
	while 1 {
		if [mlib::pathStop $curPath] {
			return 0
		}

		if [file isdirectory $curPath/.git] {
			if [file isfile $curPath/.git/config] {
				set m_gitRoot $curPath
				break
			}
		}
		set curPath [file dirname $curPath]
	}
	#read line to look for http://xxxx
	#
	set inFile [open $curPath/.git/config]
	while { [gets $inFile line] >=0 } {
		if [regexp http: $line] {
			if [regexp $mlib::FMT_IP_PORT $line addPort] {
				foreach {m_oldIP m_port} [split $addPort :] {
				}
				close $inFile
				return 1
			}
		}
	}
	close $inFile

	return 0
}


itcl::body cGit::replaceIP {} {
	global g_fileList

	if { ![string length $m_gitRoot] || ![string length $m_newIP] } {
		return 0
	}

	foreach ff $g_fileList {
		if [file exists $m_gitRoot/$ff] {
			set inFile [open $m_gitRoot/$ff]
			set outFile [open $m_gitRoot/$ff.tmp w]
			while { [gets $inFile line] >= 0 } {
				regsub $m_oldIP $line $m_newIP line
				puts $outFile $line
			}
			close $outFile
			close $inFile
			file rename -force $m_gitRoot/$ff.tmp $m_gitRoot/$ff
		}
	}
}

########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "cGit" } {
	set inDir [pwd]
	set inIP ""
	set alist $argv
	while { ![mlib::nGetOpt alist {d:i:} opt val] } {
		switch $opt {
			d {
				if { ![string equal . $val] } {
					set inDir $val
				}
			}
			i {
				if { ![regexp $mlib::FMT_IP $val inIP] } {
					puts "Input IP '$val' ignored"
				}
			}
		}
	}

	cGit gitObj $inDir $inIP
	set port [gitObj getPort]
	puts "Git repository is [gitObj getGitRoot]"
	puts -nonewline "Source from [gitObj getOldIP]:$port "
	if [string length $inIP] {
		puts "to be replaced w/ [gitObj getNewIP]:$port"
	} else {
		puts ""
	}
	itcl::delete object gitObj
}

