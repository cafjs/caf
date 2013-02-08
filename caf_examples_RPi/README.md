# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app.

See http://www.cafjs.com 

## CAF examples for an IoT linux device (like Raspberry Pi)

** UNDER CONSTRUCTION**

The device will do the following steps at startup:

    git pull the example...
    npm install  in <dir>...
    <dir>/start.js http://appname.cafjs.com/iot/<device_id>
    
Where we assume that a setup program has configured a unique `<device_id>`, the git repository location, the base url for the application, and (if needed) the wireless security configuration. 

To facilitate configuration the device could run a web server (see `caf_iot_setup`). In the case of wireless-only networking it can also start as an access point with an open network and, once wireless security has been setup using the web server, reboot as a client of the target network.
