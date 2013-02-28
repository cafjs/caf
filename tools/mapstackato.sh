#!/usr/bin/expect -f
set app [lindex $argv 0]
set timeout 120
set url [lindex $argv 1]
spawn stackato map $app $url
expect eof

