#!/usr/bin/expect -f
set app [lindex $argv 0]
set timeout 120
cd /tmp/$app
spawn stackato push --no-prompt $app
expect "deployed to Stackato"
expect eof
