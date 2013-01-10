#!/usr/bin/expect -f
set app [lindex $argv 0]
cd /tmp/$app
spawn vmc delete $app
expect "Provisioned service"
send "y\r"
expect eof 
