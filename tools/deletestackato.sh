#!/usr/bin/expect -f
set app [lindex $argv 0]
set timeout 120
cd /tmp/$app
spawn stackato delete $app
expect "Provisioned service"
send "y\r"
expect eof 
