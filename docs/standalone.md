# Running CAF locally without Cloud Foundry

We do not have debugging support in  <em>turtles</em> yet and the recommended way to develop CAF apps is to run them in a local environment first. 

## Pre-requisites

We use Linux.  Apple OS X should be similar enough. No experience with Microsoft Windows.  

Install redis >=2.6 (see http://redis.io/). We use Lua scripting in Redis and 2.4 will not work. It is likely that you will need to install from source because most  Linux distributions do no support 2.6 yet. 

In redis.conf set 'daemonize yes' and 'requirepass pleasechange' or whatever password you will use for redis.

Install node.js >= 0.8.1 (see http://nodejs.org). Create an alias in your .bashrc:  

    alias node='node --harmony-proxies'
    
so that node will always enable harmony proxies.

If needed, change dir permissions to ensure that `npm link` can write in `{prefix}/lib/node_modules` (`{prefix}` is typically `/usr/local`).

To debug CAF install `node-inspector` ( see https://github.com/dannycoates/node-inspector )

Clone `caf` from github (in https://github.com/cafjs/caf). Initialize submodules:

    git submodule init
    git submodule update
    

## Starting a  Cloud Foundry http router simulator

The simulator is in `caf_extra/caf_sim`. It is just 30 lines of `node.js` that uses the fantastic `http-proxy` package to create a local proxy that redirects http traffic and mangles cookies.  To start it:

    caf_extra/caf_sim/start.js 4000 localhost 3000
    
where `4000` is the new local port, `localhost` is where your CAF server will run, and `3000` is the port that this server is listening to (defaults to 3000 but it can be changed in framework.json as follows)


      {
            "module": "plug_cloudfoundry",
            "name": "cf",
            "description": "Enables access to config properties provided by Cloud Foundry",
            "env": {
                "port" : 3001
            }
        },

## Preparing your app for local execution

You need to configure `framework.json` in your app so that it uses the local Redis service:

       {
            "module": "plug_cloudfoundry",
            "name": "cf",
            "description": "Enables access to config properties provided by Cloud Foundry",
            "env": {
                "redis" : {
                    "hostname" : "localhost",
                    "port" : 6379,
                    "password" : "pleasechange"
                }
            }
        },

Then, set up the environment:

    tools/setupLinks.sh

and package your app (assumed in the `caf_examples` dir):

    tools/cpexample.sh helloworld
    
    
This creates a directory `/tmp/helloworld` with your app+dependencies (and a tarball `/tmp/helloworld.tgz` if you want to deploy remotely with `turtles`). 

## Running your app locally

Assuming that the simulator and Redis are  already running, just type:

    cd /tmp/helloworld; node index.js
    
The server should be up now. Type the following url in a browser:

    http://helloworld.vcap.me:4000/app.html
    
    
and after logging in using the `accounts` service (serviceUrl location in `framework.json`) you should see the app in your browser.

Note that the domain `*.vcap.me` always resolves to your localhost, and we need it to avoid (browser) caching problems created by using  `http://localhost:4000/app.html` with different applications.

## Debugging your app

The first step is to increase the logger output. For example, to set the logger to `TRACE` mode, change in `framework.json`:


    {
        "module": "plug_log",
        "name": "log",
        "description": "Logging of errors and debugging info\n Properties: <logLevel> Threshold for logging: OFF, FATAL, ERROR, WARN, INFO, DEBUG and TRACE (in that order).",
        "env": {
            "logLevel" : "TRACE"
        }
    },
    
    
It also helps to create a client session with Redis and lookup the internal state of CAs or monitor CAF updates:

    redis-cli -a pleasechange
    keys *
    mget data:antonio_m1
    monitor
    
But in most cases it is best to use two debuggers: one to set breakpoints in the client (using the browser's debugger) and the other one attached to  CA code (i.e., using node-inspector). This allows you to examine the state of the system as you follow  requests  from client to CA and back. To do that, first start CAF server in debug mode:

    
    {
        "module": "sup_main",
        "name": "sup",
        "description": "Top level Supervisor component...",        
        "env": {
            "debugger": true
            ...
            
            
Then, start node-inspector:

    .bin/node-inspector
    
and use a browser to attach to that process using the URL:

    http://0.0.0.0:8080/debug?port=5858
    
and now you can use a separate browser window to load the app and set breakpoints in the client code.
    
    
    
    

    
    
