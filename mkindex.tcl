#tclsh mkindex.tcl

#
# create index
proc buildIndex {} {
	puts -nonewline "Creating tclIndex ..."
	flush stdout
	auto_mkindex . *.tcl
	puts " done !"
}

#####
# main
# ask user if tclIndex exists
#
if [file exists tclIndex] {
	puts -nonewline {tclIndex exists, process anyway? (y/n) }
	flush stdout
	gets stdin ans
} else { set ans yes }


switch -regexp -nocase -- $ans {
	^y.* {
		file delete tclIndex
		buildIndex
	}
}

