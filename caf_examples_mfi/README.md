# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app.

See http://www.cafjs.com 

## CAF examples for managing a wifi enabled power strip (like mPower by Ubiquity)

** UNDER CONSTRUCTION**

The mPowerTM power strip can measure energy consumption per port and switch them on/off using built-in relays. It has wifi connectivity and runs Linux with a Mips processor. It does not have enough memory to run node.js so we use a Lua client instead (see `caf_extra/caf_iot_cli/lua`). The mPower does not include a needed luasocket library compiled for Mips that you can find in `caf_mfi_setup`.

