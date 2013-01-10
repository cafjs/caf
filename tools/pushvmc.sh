#!/usr/bin/expect -f
set app [lindex $argv 0]
cd /tmp/$app
spawn vmc push $app
expect "Would you like to deploy"
send "Y\r"
expect "Application Deployed URL"
send "\r"
expect "Detected a Node.js "
send "Y\r"
expect "Memory Reservation"
send "\r"
expect "Would you like to bind "
send "y\r"
expect "Would you like to use an existing" {send "\r"}
expect "Please select one you wish to provision"
send "2\r"
expect "Specify the name of the service"
send "\r"
expect eof 
