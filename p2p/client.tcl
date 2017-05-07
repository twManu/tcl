set server localhost
#set server 72.3.15.3
#set sockChan [socket $server 9900]
set sockChan [socket $server [lindex $argv 0]]
puts "[fconfigure $sockChan -sockname] [fconfigure $sockChan -peername]"
gets $sockChan line
close $sockChan
puts "The time on $server is $line"
