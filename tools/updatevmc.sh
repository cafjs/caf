#!/usr/bin/expect -f
set app [lindex $argv 0]
cd /tmp/$app
spawn vmc update $app
expect eof 
