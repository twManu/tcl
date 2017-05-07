#run tclsh replace.tcl in p2p directory
#for each subdirectory has xxx.log, the log file will be trimmed and ip replaced
#the output will be xxx.mod
set g_delList [list\
	"natserverProc: <<SERV"\
	"local ip"\
	"XSTUNT"\
	"handshakeRTT"\
	"SHAREfrom"\
	"NAT"\
	"no player"\
	"initIncoming"\
	"readHostAtoms"\
	"addHit"\
	"printChanHitList"\
	"idleProc"\
	"allocServent:"\
	"startThread:"\
	"fetchProc:"\
	"reportProc:"\
	"readBroadcastAtoms:"\
	"RTT--"\
	"deRegX"\
	"Peer-- Sent #"\
	"Got packet <"\
	"mediaSchedule"\
	"noShareHitID"
]

array set g_replace {
	192\.168\.3\.101:38585 111.241.75.1:38585
}


foreach ff [lsort [glob -type f */*.log]] {
	regsub {\.log$} $ff {.mod} fnameOutput   ;#output file name  xxx.log->xxx.mod
	set inFile [open $ff]
	set outFile [open $fnameOutput w]
	
	while { [gets $inFile line] >= 0 } {  ;#read each line
		set noWrite 0
		foreach token $g_delList {
			if [regexp $token $line] {
				incr noWrite
				break
			}
		}
		if { !$noWrite } {
			#check and replace
			foreach src [array names g_replace] {
				if [regsub -all $src $line $g_replace($src) line] {
					break	;#assume only one addr:port in a line
				}
			}
			puts $outFile $line
		}
	}

	close $outFile
	close $inFile
}
