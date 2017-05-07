#tclsh util.tcl

#
# set value = !value
# In    : refVar - reference of variable
# Out   : refVar is logically inverted
# Ret   : new value returned
proc toggleVar {refVar} {
	upvar $refVar var
	set var [expr !$var]
}


