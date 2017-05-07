proc Server {channel clientaddr clientport} {
	puts "Connection from $clientaddr registered"
	puts $channel [clock format [clock seconds]]
	close $channel
}

#socket -server Server 9900
set sockChan [socket -server Server 0]
foreach {addr hostname port} [fconfigure $sockChan -sockname] {
	puts "Server is listening port $port"
}
vwait forever
exit

#ok recursive
proc factorial {n {accum 1}} {
	if {$n < 2} {
		return $accum
	}
	return [factorial [expr {$n - 1}] [expr {$accum * $n}]]
}

puts "[factorial [lindex $argv 0]]"