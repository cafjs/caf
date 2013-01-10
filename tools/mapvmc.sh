#!/usr/bin/expect -f
set app [lindex $argv 0]
set url [lindex $argv 1]
spawn vmc map $app $url
expect eof
