#!/usr/bin/expect -f
set app [lindex $argv 0]
set timeout 180
cd /tmp/$app
spawn stackato push --health-timeout 180 --reset  --no-prompt --as $app
expect "deployed"
expect eof
