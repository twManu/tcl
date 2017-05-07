#
#to make sure all upper path is searched for mlib
#

#search from where we are upto root
set g_progPath [pwd]
#the current and known directories must check
set g_pathToInclude "C:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4 e:/Tcl/lib/teapot/package/win32-ix86/lib/Itcl3.4 C:/Tcl/lib/itcl4.0.2"
while 1 {
	#remove "d:"
	regsub -nocase -- {^[a-z]:} $g_progPath {} tmpPath
	if ![string length tmpPath] {break}
	if { [string equal $tmpPath .] || [string equal $tmpPath /] } {	break }
	#puts $g_progPath
	#it works when path has blank, say "WM file"
	lappend g_pathToInclude $g_progPath
	set g_progPath [file dirname $g_progPath]
}

foreach pp $g_pathToInclude {
	if {[lsearch $::auto_path $pp]<0} {                    ;#add those not yet in path
		if {[catch {glob -type f $pp/*.tcl} msg]} { continue }
		lappend ::auto_path $pp                            ;#and add those contain *.tcl
	}
}

package require Itcl
package require mlib
#package require cBinField 1.0
source cBinField.tcl
set DBG_BD	0		;#0 (off) or otherwise (on)

#state
array set g_stField {
	gold                 0
	food                 1
	iron                 2
	fur                  3
	price                4
	water                5
	earth                6
	wealth               7
	support              8
	weapen               9
	training             10
	unknown11            11
	unknown12            12
	unknown13            13
	unknown14            14
	unknown15            15
	unknown16            16
	unknown17            17
	unknown18            18
	unknown19            19
}

variable g_stFieldList {
	"黃金 su"
	"糧草 su"
	"金屬 su"
	"毛皮 su"
	"物價 c"
	"治水 c"
	"地利 c"
	"財富 c"
	"支持 cu"
	"武器 c"
	"戰技 c"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
}

array set g_stFields {}

#for readability
#bit 0x02 of role is bortherhood
array set g_bdField {
	age                  0
	country              1
	state                2
	body                 3
	bodyLimit            4
	justice              5
	mercy                6
	courage              7
	strength             8
	skill                9
	wisdom               10
	strengthExp          11
	skillExp             12
	wisdomExp            13
	loyalty              14
	icon                 15
	fame                 16
	soldier              17
	role                 18
	unknown19            19
	unknown20            20
	unknown21            21
}

# one to one mapping to g_bfField
variable g_bdFields {
	"年齡 cu"
	"國屬 cu"
	"州郡 cu"
	"體力 cu"
	"上限 cu"
	"忠義 cu"
	"仁愛 cu"
	"勇氣 cu"
	"力量 cu"
	"技能 cu"
	"智力 cu"
	"力量經驗 cu"
	"技能經驗 cu"
	"智力經驗 cu"
	"忠誠 cu"
	"人像 cu"
	"人望 su"
	"士兵 cu"
	"身份 cu"
	"未知 cu"
	"未知 cu"
	"未知 cu"
}

array set g_field {}
# leader must have properties 99 99 99 
array set g_leader {
	"林沖"		"100 61 80"
	"宋江"		"81 100 62"
	"史進"		"74 69 95"
	"晁蓋"		"96 68 76"
	"楊志"		"97 58 79"
	"魯智深"	"63 74 88"
	"武松"		"68 55 98"
}

array set g_people {
	"91 75 84"	"花榮"
	"100 61 80"	"林沖"		
	"79 78 90"	"秦明"
	"81 100 62"	"宋江"		
	"75 90 83"	"關勝"
	"74 69 95"	"史進"		
	"86 70 58"	"吳用"		
	"96 68 76"	"晁蓋"		
	"97 58 79"	"楊志"		
	"63 74 88"	"魯智深"	
	"68 55 98"	"武松"		
	"68 63 81"	"盧俊義"	
	"72 66 83"	"張清"		
	"82 51 73"	"董平"		
	"54 68 72"	"孫立"		
	"62 41 89"	"索超"		
	"59 72 53"	"朱同"		
	"42 73 54"	"李云"		
	"77 41 50"	"王煥"		
	"44 60 27"	"時文彬"	
	"72 50 44"	"朱武"		
	"54 53 58"	"徐寧"		
	"45 31 69"	"王英"		
	"62 31 41"	"周通"		
	"35 27 71"	"劉唐"		
	"10 22 10"	"潘巧雲"	
	"42 28 51"	"季三思"	
	"32 29 59"	"鄧飛"		
	"70 35 53"	"黃安"		
	"40 32 64"	"蘇定"		
	"84 29 20"	"蔡京"		
	"32 37 61"	"楊春"		
	"53 25 36"	"陳達"		
	"29 20 23"	"李吉"		
	"25 20 57"	"崔道成"	
	"19 12 40"	"丘小乙"	
	"53 36 62"	"王倫"		
	"76 42 22"	"朱貴"		
	"46 27 29"	"杜遷"		
	"34 25 28"	"宋萬"		
	"24 10 26"	"鄧龍"		
	"17 14 28"	"李鬼"		
	"38 52 43"	"薛永"		
	"50 42 38"	"阮小七"	
	"73 94 40"	"宿元景"	
	"67 46 82"	"高濂"		
	"71 54 50"	"單廷珪"	
	"83 32 55"	"雷橫"		
	"24 20 42"	"張蒙方"	
	"59 43 80"	"黃信"		
	"60 79 42"	"張叔夜"	
	"52 73 51"	"魏定國"	
	"45 68 49"	"裴宣"		
	"41 64 56"	"楊雄"		
	"40 39 48"	"龔旺"		
	"50 33 36"	"牛邦喜"	
	"35 26 27"	"張世開"	
	"20 38 23"	"王定六"	
	"31 28 50"	"鮑旭"		
	"44 18 38"	"河濤"		
	"16 43 20"	"張文遠"	
	"14 32 25"	"西門慶"	
	"35 12 10"	"劉高"		
	"18 16 29"	"張保"		
	"40 52 29"	"淩振"		
	"46 29 38"	"楊林"		
	"45 32 36"	"郝思文"	
	"75 39 61"	"丘岳"		
	"84 29 56"	"鈕文忠"
	"60 33 82"	"史文恭"
	"90 54 65"	"燕青"
	"87 70 73"	"蕭嘉穗"
	"48 34 76"	"杜微"
	"79 91 73"	"王進"
	"92 73 77"      "瓊英"
	"75 88 79"      "許貫忠"
}


# In   : msg - message to output
#        newline - 0 : no newline
#          otherwise : newline applied (default)
proc dbgRK {msg {newline 1}} {
	global DBG_BD
	if { $DBG_BD } {
		if { $newline } {
			puts "$msg"
		} else {
			puts -nonewline "$msg"
		}
	}
}


itcl::class cBdST {
	private variable m_fieldArray

	# Init with 22 raw data read originally
	# the m_fieldArray(0) will hold field 0 in g_field
	constructor { varName rawData } {
		global g_stFields
		set pos 0
		foreach i [lsort -integer [array names g_stFields]] {
			foreach {name cmd} [split $g_stFields($i)] {
				set vname "field$i"
				set vname "$varName$vname"
				eval "cBinField $vname $name $cmd"
				eval "$vname create \$rawData pos"
				eval "set m_fieldArray($i) $vname"
			}
		}
	}

	# Deinit constructor
	destructor {
		foreach {dummay obj} [array get m_fieldArray] {
			itcl::delete object $obj
		}
	}
	
	#macro for access name in m_fieldArray
	private method myName {index} {
		global g_stField
		return [eval \$m_fieldArray\(\$g_stField\(\$index)) name]
	}
	private method myValue {index} {
		global g_stField
		return [eval \$m_fieldArray\(\$g_stField\(\$index)) value]
	}
	private method myValueH {index} {
		global g_stField
		return [eval \$m_fieldArray\(\$g_stField\(\$index)) valueH]
	}
	private method setValue {index value} {
		global g_stField
		return [eval \$m_fieldArray\(\$g_stField\(\$index)) setValue $value]
	}

	method print { } {
		puts "[myName support]: [myValue support] \([myValueH support])"
		puts -nonewline "[myName gold]: [myValue gold] \([myValueH gold])   [myName food]: [myValue food] \([myValueH food])   "
		puts "[myName iron]: [myValue iron] \([myValueH iron])   [myName fur]: [myValue fur] \([myValueH fur])"
		puts -nonewline "[myName water]: [myValue water] \([myValueH water])  [myName earth]: [myValue earth] \([myValueH earth])  "
		puts "[myName wealth]: [myValue wealth] \([myValueH wealth])"
		puts "[myName weapen]: [myValue weapen]   [myName training]: [myValue training]"
		puts -nonewline "[myName unknown11]: [myValue unknown11] [myValue unknown12] [myValue unknown13] "
		puts -nonewline "[myValue unknown14] [myValue unknown15] [myValue unknown16] "
		puts "[myValue unknown17] [myValue unknown18] [myValue unknown19]"
	}
	method getBinStr {} {
		set binStr {}
		foreach {index} [lsort -integer [array names m_fieldArray]] {
			append binStr [$m_fieldArray($index) valueB]
		}
		return $binStr
	}
	method update {} {
		#print
		setValue gold 20000
		setValue food 20000
		setValue iron 20000
		setValue water 100
		setValue earth 100
		setValue wealth 100
		setValue support 100
		setValue weapen 100
		setValue training 100
	}
}


itcl::class cBdMan {
	private variable m_fieldArray             ;#m_fieldArray(0) is field object holding "年齡"
	private variable m_attr                   ;#"m_justice  m_mercy m_courage"
	private variable m_attrHex                ;#in hex
	private variable m_capHex                 ;#capabilites
	private variable m_index
	private variable m_name     "???"         ;#if no match ??? is shown
	private variable m_brother    ""          ;#if led by bother

	# Init with 22 raw data read originally
	# the m_fieldArray(0) will hold field 0 in g_field
	constructor { index rawData } {
		global g_field g_people
		set pos 0
		set m_index $index
		set m_attr ""
		
		#create fields
		foreach i [lsort -integer [array names g_field]] {
			foreach {name cmd} [split $g_field($i)] {
				set vname fello"$index"field$i
				eval "cBinField $vname $name $cmd"
				eval "$vname create \$rawData pos"
				eval "set m_fieldArray($i) $vname"
				if { [string equal $name "忠義"]
				  || [string equal $name "仁愛"]
				  || [string equal $name "勇氣"] } {
					eval "lappend m_attr \[$vname value]"
					eval "lappend m_attrHex \[$vname valueH]"
				}
			}
		}
		set m_attrHex "\($m_attrHex)"
		set m_capHex "\([myValueH strength] [myValueH skill] [myValueH wisdom])"
		#looking for name with attr assuming attr is exclusive
		if [info exists g_people($m_attr)] {
			set m_name $g_people($m_attr)
			dbgRK "$m_name $m_attr $m_attrHex"
		}
	}

	# Deinit constructor
	destructor {
		foreach {dummay obj} [array get m_fieldArray] {
			itcl::delete object $obj
		}
	}
	#macro for access name in m_fieldArray
	private method myName {index} {
		global g_bdField
		return [eval \$m_fieldArray\(\$g_bdField\(\$index)) name]
	}
	private method myValue {index} {
		global g_bdField
		return [eval \$m_fieldArray\(\$g_bdField\(\$index)) value]
	}
	private method myValueH {index} {
		global g_bdField
		return [eval \$m_fieldArray\(\$g_bdField\(\$index)) valueH]
	}
	private method setValue {index value} {
		global g_bdField
		return [eval \$m_fieldArray\(\$g_bdField\(\$index)) setValue $value]
	}

	method setName {name} {
		if [isLeader] {
			set m_name $name
		} else {
			puts "only allow setting name for leader"
		}
	}

	# if country == brother, set country as name
	# Ret: the state of this man, so forms brother's territory
	#      state not biased and is one less than what users see
	method setCountryName {brotherIndex name} {
		global g_bdField
		if {[myValue country]==$brotherIndex} {
			set m_brother $name
			return [myValue state]
		}
		return -1
	}
	method isLeader {} { return [matchAttr "99 99 99"] }
	method print {{indexOnly 1}} {
		puts "**** $m_name\($m_index) ****"
		if {!$indexOnly} {
			puts -nonewline "[myName country]/[myName state]: "
			if [string length $m_brother] {
				puts -nonewline "$m_brother"
			} else {
				puts -nonewline "[myValue country]"
			}
			puts -nonewline "/[expr [myValue state] + 1]"
			if [isLeader] {
				puts "   [myName fame]: [myValue fame] "
			} else {
				puts ""
			}

			puts -nonewline "[myName loyalty]: [myValue loyalty]          [myName age]: [myValue age]    [myName role]: [myValue role]   "
			puts "[myName icon]: [myValue icon]"
		
			puts "[myName body]: [myValue body]\([myValue bodyLimit])   [myName soldier]: [myValue soldier]"
			puts "[myName justice] [myName mercy] [myName courage]: $m_attr $m_attrHex"

			puts -nonewline "[myName strength] [myName skill] [myName wisdom]: "
			puts "[myValue strength].[myValue strengthExp] [myValue skill].[myValue skillExp] [myValue wisdom].[myValue wisdomExp] $m_capHex"
			puts "[myValue unknown19] [myValue unknown20] [myValue unknown21]"
		}
	}
	method matchAttr {attr} {
		return [string equal $attr $m_attr]
	}
	method update {} {
		setValue body 255
		setValue bodyLimit 255
		setValue strength 100
		setValue skill 127
		setValue wisdom 254
		setValue loyalty 100
		setValue soldier 100
		#puts "[string range [getBinStr] 0 21]"
		#brother hood
		set roleVal [myValue role]
		set roleVal [expr $roleVal | 2]
		setValue role $roleVal
	}
	#00 appended binary string returned
	method getBinStr {} {
		set binStr {}
		foreach {index} [lsort -integer [array names m_fieldArray]] {
			append binStr [$m_fieldArray($index) valueB]
		}
		return $binStr
	}
	method setBrother {} {
		setValue body 255
		setValue bodyLimit 255
		setValue justice 99
		setValue mercy 99
		setValue courage 99
		setValue strength 110
		setValue skill 127           ;# 254 fails to build ship
		setValue wisdom 127          ;# 254 fails to recruit leaders
		setValue fame 999
		setValue soldier 160
	}
}


itcl::class cBdParser {
	#people constant
	#
	private variable OFFSET_MAN              [expr 0x10]            ;#first man file offset
	private variable SIZE_PER_MAN            22
	private variable NR_PEOPLE               255
	#state constant
	#
	private variable OFFSET_ST               5964
	private variable SIZE_PER_ST             24
	private variable NR_ST                   49
	#state db
	private variable m_stArray
	#people db
	private variable m_manArray
	#file name
	private variable m_fileName              ""
	private variable m_leaderIndex           -1                  ;#no found if <0
	private variable m_leaderName            ""
	private variable m_territory             {}                  ;#list of states (user state) belongs to brother

	# Init
	constructor { inFile } {
		#inFile is a list so we need to "lindex" in advance
		set m_fileName [file normalize [lindex $inFile 0]]
		parsing
	}

	# Deinit constructor (parse)
	destructor {
		foreach {index obj} [array get m_manArray] {
			itcl::delete object $obj
		}
	}

	# start processing
	private method parsing {}
	# find if 99 99 99 fellow present
	private method setLeaderName {}

	# find 
	method printLeader {}
	method possibleLeader {}
	method dump {{all 0}}
	method showState {{indexList {}}}
	method showTerritory {}
	method showCharaster {{indexList {}} {indexOnly 1}}

	# field
	# 0 : charm
	# 1 : force
	# 2 : widsom
	method sort { field {count 15} }
	method update { manList stList }
	private method write { {mans {}} {states {}} }
	method setBrother {index}
}

itcl::body cBdParser::setBrother {index} {
	if [info exists m_manArray($index)] {
		$m_manArray($index) setBrother
	}
	write $index
}

#state is a list of programming state (one less than game state)
itcl::body cBdParser::write { {mans {}} {states {}} } {
	if { [catch {set channel [open $m_fileName a+]} msg] } {
		puts "Fail to open $m_fileName for write"
		exit
	}

	fconfigure $channel -translation binary -encoding binary
	
	if [llength $mans] {
		puts -nonewline "... writing fellow "
		foreach index [lsort -integer $mans] {
			puts -nonewline "$index "
			set wPoint [expr $OFFSET_MAN + $index \* $SIZE_PER_MAN]
			chan seek $channel $wPoint start
			set data [string range [$m_manArray($index) getBinStr]\
					0 [expr $SIZE_PER_MAN - 1]]
			puts -nonewline $channel $data
		}
		puts ""
	}
	
	if [llength $states] {
		puts -nonewline "... writing state "
		foreach index [lsort -integer $states] {
			puts -nonewline "[expr $index + 1] "
			set wPoint [expr $OFFSET_ST + $index \* $SIZE_PER_ST]
			chan seek $channel $wPoint start
			set data [string range [$m_stArray($index) getBinStr]\
					0 [expr $SIZE_PER_ST - 1]]
			puts -nonewline $channel $data
		}
		puts ""
	}
	close $channel
}


itcl::body cBdParser::printLeader {} {
	 if {$m_leaderIndex>=0 } {
		$m_manArray($m_leaderIndex) print 0
	}
}

itcl::body cBdParser::setLeaderName {} {
	global g_leader
	
	#give up if no 99 99 99 found
	if {$m_leaderIndex<0} { return }
	#mark all true
	foreach {name attr} [array get g_leader] {
		set beLeader($name) 1
	}
	#if possible leader found same attr, it is not a leader
	foreach {name attr} [array get g_leader] {
		foreach {index} [lsort -integer [array names m_manArray]] {
			if [$m_manArray($index) matchAttr $attr] {
				set beLeader($name) 0
				break
			}
		}
	}
	foreach {name attr} [array get g_leader] {
		if $beLeader($name) {
			$m_manArray($m_leaderIndex) setName $name
			set m_leaderName $name
			break
		}
	}
}

#show n-th (0-based) character and if indexOnly, 
itcl::body cBdParser::showCharaster {{indexList {}} {indexOnly 1}} {
	global g_people
	
	foreach index [lsort -integer $indexList] {
		if { $index<0 || $index>$NR_PEOPLE } {
			puts "character index out of range"
		} else {
			$m_manArray($index) print $indexOnly
		}
	}
}

itcl::body cBdParser::showTerritory {} {
	if [llength $m_territory] {
		puts [lsort -integer $m_territory]
	} else {
		puts "no brother found or no state occupied"
	}
}

itcl::body cBdParser::showState {{indexList {}}} {
	if [llength $indexList] {
		foreach {index} [lsort -integer $indexList] {
			if { $index<0 || $index>$NR_ST } {
				puts "state $index out of range"
			} else {
				$m_stArray([expr $index -1]) print
			}
		}
	} else {
		foreach {index} [lsort -integer [array names m_stArray]] {
			puts -nonewline "state [expr 1 + $index] ===>  "
			$m_stArray($index) print
			puts ""
		}
	}
}

#stList is list of state in game (one more with programming state)
#if -1 in the stList, whole territory will be updated
itcl::body cBdParser::update {manList stList} {
	foreach {man} [lsort -integer $manList] {
		$m_manArray($man) update
	}
	set biasState {}
	#replace stList if 
	if {[lsearch -integer $stList -1]>=0} {
		puts "whole territory updated"
		set stList $m_territory
	}
	foreach {state} [lsort -integer $stList] {
		incr state -1
		lappend biasState $state
		$m_stArray($state) update
	}
	write $manList $biasState
}

itcl::body cBdParser::dump {{all 0}} {
	if {$all} {
		set indexOnly 0
	} else {
		set indexOnly 1
	}

	foreach {index} [lsort -integer [array names m_manArray]] {
		showCharaster $index $indexOnly
	}
}

itcl::body cBdParser::possibleLeader {} {
	global g_leader
	
	foreach {name attr} [array get g_leader] {
		set found 0
		foreach {index} [lsort -integer [array names m_manArray]] {
			if [$m_manArray($index) matchAttr $attr] {
				;#no break to find out duplication
				incr found
				$m_manArray($index) print 0
				puts ""
			}
		}
		if {! $found } {
			printLeader
			puts ""
		}
	}
}


#
# field: The field to compare with
# count: Number of people printed
itcl::body cBdParser::sort { field {count 15} } {
	array set fieldName {
		0      "     (c)  f  w  sum"
		1      "       c  (f)  w  sum"
		2      "       c  f  (w) sum"
		3      "      c   f  w  (sum)"
	}

	if { $field<0 || $field>[array size fieldName] } {
		puts "Invalid field $field"
		exit
	}

	puts "$fieldName($field)"
	set nameValue {}
	incr field
	
	foreach {name value} [array get m_people] {
		lappend nameValue [linsert $value 0 $name]
	}
	set i 0
	foreach {element} [lsort -integer -decreasing -index $field $nameValue] {
		if { $i>=$count } { break }
		puts "$element"
		incr i
	}
}


itcl::body cBdParser::parsing {} {
	#todo normalize
	if { [catch {set channel [open $m_fileName]} msg] } {
		puts "Fail to open $m_fileName"
		exit
	}

	fconfigure $channel -translation binary
	chan seek $channel $OFFSET_MAN start

	#tricky!!!
	#create object fellow0field0, fellow0field1 ..., then fellow1field0, fellow1field1
	#NR_PEOPLE
	for {set i 0} {$i<$NR_PEOPLE} {incr i} {
		set rawData [read $channel $SIZE_PER_MAN]
		eval "cBdMan fellow$i $i \$rawData"
		set m_manArray($i) fellow$i
		if [fellow$i isLeader] { set m_leaderIndex $i }
	}
	
	#state db
	chan seek $channel $OFFSET_ST start
	for {set i 0} {$i<$NR_ST} {incr i} {
		set stNr [expr $i + 1]
		set rawData [read $channel $SIZE_PER_ST]
		eval "cBdST state$stNr state$stNr \$rawData"
		set m_stArray($i) state$stNr
	}

	close $channel
	setLeaderName
	#update country name if the country of this man is leader index, change the index and leader name
	if {$m_leaderIndex>=0} {
		foreach {index} [array names m_manArray] {
			set state [$m_manArray($index) setCountryName $m_leaderIndex $m_leaderName]
			if {$state < 0} {continue}
			#add 1 to user state
			incr state
			if {[lsearch -integer $m_territory $state]<0} {
				lappend m_territory $state
			}
		}
	}
}


########
# main
# Code below runs when this is launched as the main script
# It is otherwise a library and be quiet
#
if { [file root [file tail $argv0]] == "bandit" } {
	proc usage {} {
		puts "Usage: bandit -f FILE \[-q QUERY] \[-d] \[-D]"
		puts "   f: file name of saved data"
		puts "   q: query data"
		puts "       L - show possible leaders"
		puts "       l - find property 99 in leaders"
		puts "       s - show state"
		puts "       t - show territory"
		puts "    d: dump known characters' index"
		puts "    D: dump known characters"
		puts ""
		puts "       bandit -f FILE \[-l LEADER_INDEX] \[-s STATE_INDEX] \[-u man] \[-b man] \[-U state] \[-S]"
		puts "   f: file name of saved data"
		puts "   l: specify the leader index got by query"
		puts "   s: specify the state index got by query"
		puts "   u: man to update, can be many"
		puts "   U: state to update, can be many"
		puts "   b: setting brother, 99 99 99"
		puts "   S: all state of brother are updated"
		exit
	}
	proc createBdField {} {
		global g_field g_bdField g_bdFields
		if { [array size g_bdField] != [llength $g_bdFields] } {
			puts "size mismatch between field and field list"
			exit
		}
		foreach {fname index} [array get g_bdField] {
			set g_field($index) [lindex $g_bdFields $index]
		}
		global g_stField g_stFieldList g_stFields
		if { [array size g_stField] != [llength $g_stFieldList] } {
			puts "size mismatch between state field and field list"
			exit
		}
		foreach {fname index} [array get g_stField] {
			set g_stFields($index) [lindex $g_stFieldList $index]
		}

	}
	set alist $argv
	set fileName "/data/SAN5/bandit/savedata"
	set query ""
	set bandit {}
	set state {}
	set dump 0
	set updateMan {}
	set updateST {}
	set brother -1
	while { ![mlib::nGetOpt alist {hq:f:dDs:l:u:U:b:S} opt val] } {
		switch $opt {
			f { set fileName $val }
			d { incr dump }
			D { set dump 2 }
			q { set query $val }
			s { lappend state $val }
			l { lappend bandit $val }
			u { lappend updateMan $val }
			U { lappend updateST $val }
			b { set brother $val }
			S { lappend updateST -1 }
			default { usage }
		}
	}

	if { ![string length $fileName] } usage
	createBdField
	
	cBdParser db $fileName
	if { $brother>=0 } {
		db setBrother $brother
	} elseif { [llength $updateMan] || [llength $updateST] } {
		#puts "man: $updateMan, state: $updateST"
		db update $updateMan $updateST
	} elseif $dump {
		db dump [expr $dump - 1]
	} elseif [string length $query] {
		switch $query {
			l { db printLeader }
			L { db possibleLeader }
			s { db showState }
			t { db showTerritory }
			default { usage }
		}
	} elseif [llength $state] {
		db showState $state
	} elseif [llength $bandit] {
		db showCharaster $bandit 0
	}
	itcl::delete object db
}

