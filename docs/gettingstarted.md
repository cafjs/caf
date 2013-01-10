#  <a id="top"></a>Getting started

By the end of this tutorial you should be able to:

* Write a simple CA that maintains its own state, exports public methods that 
can be called by the client, and implements life-cycle methods that are called 
by the framework
* Add autonomous behavior with the 'pulse' framework method
* Understand how your GUI interacts with it
* Add the ability to asynchronously send notifications to your client
* Manage these notifications by using logical sessions and direct manipulation of output queues
* Add a service to facilitate interactions between CAs 

We use a simple counter example (pun intended) to introduce these concepts. The CA's state is just a number representing the counter. 

As you make your way through this tour of the CAF, we demonstrate how you can:

* initialize the counter and export methods that the client can use to read or increment its value 
* limit the number of pending notifications or choose which client device (or all) should receive a notification

In addition, we'll show you how you can get CAs to do some useful things:

* periodically increment counters on their own
* notify clients when their counter reaches a multiple of 5 (or of another value)
* tell each other that they have reached certain value by using a (pub/sub) service

For our examples we put together a bare-bones GUI using Enyo. If the GUI looks ugly blame us not Enyo! Please also take note that this is not a tutorial about Enyo (see http://enyojs.com) and it should be easy to adapt the same ideas to other client frameworks.

## Before we start

Source code for the examples is in github <http://>

We follow a standard node.js package layout, and we add a `/public` dir that contains the client app. Also, in the `/lib` dir
there is always a file called `ca_methods.js` that implements the CA. 
By default, the framework looks for this file name  to bootstrap the system. Please do not rename that file. 

Another two files (also in `/lib`) that will soon be familiar to you are `ca.json` and `framework.json`. They define how to configure a CA and how to configure the framework. 

File `rsa_pub.pem` contains the public key of the Accounts service. This service issues signed authentication tokens that enable single sign-on for your app.

The behavior of the Enyo-based GUI is defined by `App.js` in `/public/source`.

All the tutorial examples are already deployed and you can use the launcher to see what they do. We call them tutorial1a, tutorial1b, tutorial1c...No, we don't have an tutorial2, but it's good to plan for the future.

But the fun part is when you start tinkering with them. To see the results, you'll need to use Turtles, our deployment app. Simply create a tar file with the app and its dependencies (the script ./cpexample `<appname>` should do that for you by creating a tar file  in /tmp/...). Then, leave that tar file where Turtles can see it (a public url hosted by a service like HP Object Storage, a public folder in Dropbox,  or your website outside the firewall - just making sure that this website can give you ETag header info), give it a name, and Turtles will do the rest. If you toggle the setting to Auto, Turtles tracks changes to the contents of the url and asks you to upgrade when needed. 

We don't have debugging support in Turtles right now, and if you get stuck you may want to run everything locally first, [Running CAF Locally](standalone.html) where you can use standard node.js debugging tools like [node-inspector](https://github.com/dannycoates/node-inspector). 

## <a id="basics"></a>Tutorial 1a) The basics

* initializing a CA
* defining framework methods
* calling public methods from your client
* modifying internal CA state


Let's look at file lib/ca_methods.js. This is the main file that defines the behavior of the CA and starts the framework. 

It is just a node.js file that loads the core module:

    var caf = require('caf_core');

exports a bunch of methods:

    exports.methods = {
              ....
    }


and starts the framework:

    caf.init(__dirname, {});


Methods are exported with an object that can  *only* contain plain functions, which means you cannot use closures or other object variables. 

We follow a simple naming convention; the prefix `__ca_` indicates a framework method that can only be called by the framework, otherwise it's a public method (typically called by the remote client app).

### Callbacks

Both framework and public methods use a standard callback convention and in good node.js tradition take two arguments `cb(err, data)` . When the first argument `err` is falsy it means everything went fine and the result is in `data`. Otherwise, we get an error condition as described by `err`:

    'increment' : function(..., cb) {    
      cb(err, data);
    }

Ok, but where does `cb` come from and why do we need it? 

The framework creates a fresh `cb` for each call and it is just a way for your code to tell the framework "I'm done processing this request, this is what happened with it, give me the next one". 

We cannot just  'return' like a normal function because this is node.js, and we may want to do multiple non-blocking operations before we are actually ready to process the next request. If you want to know more about Actors, and the rationale behind all this, see [CAF Design](framework.html).

A common bug is to return without calling `cb`. In that case the CA hangs until the cron ripper detects that condition and shuts it down.

### State

How do you add state to your CA if you cannot use closures or object variables in the `methods` object?

Whenever the framework creates a new CA it starts with an empty object, adds all the methods in `methods` and creates in it an empty object `this.state`. This object contains anything you want as long as it is JSON serializable. 

We need JSON serializable contents because the framework regularly checkpoints `this.state` in a remote server.

### Framework methods

Two framework methods that typically change  `this.state` are:   

    '__ca_init__' : function(cb) {
        this.state.counter = -1;
        cb(null);
    },
    '__ca_resume__' : function(cp, cb) {
        this.state = (cp && cp.state) || {};
        cb(null);
    },
    
where `__ca_init__` is only called once in the lifetime of a CA, and gives your code a chance to do a first initialization.

 `__ca_resume__` is called by the framework many times. For example, when updating the code that implements this CA, or when migrating this CA to a different server, or when restarting immediately after a crash. 
 
`__ca_resume__` takes an argument `cp` that  reflects the last checkpoint of `this.state`. We guarantee that `cp` is really the last one, since nobody has been able to observe a more recent state--we always checkpoint before externalizing state. 

Note how we call the callback `cb` with a falsy (i.e., `null`) argument to indicate that everything went fine. 

### Public methods

Public methods follow the same structure:

    'increment' :function(inc, cb)  {
        this.state.counter = this.state.counter + inc;
        cb(null, {counter : this.state.counter});    
    }
    
Here the argument `inc` is provided by the client. Since the first argument in the callback is `null` we return the object `{counter : this.state.counter}` to the caller--don't forget it also should be JSON serializable, since it goes over the network.


### Errors

The CA is designed to start up once, keep running indefinitely, and always maintain the last exposed state. To accomplish this, we have designed it so that changes to `this.state` are transactional. The transaction starts with the method invocation and finishes with the end of the callback. Errors simply abort the transaction. For example:

    'increment' :function(inc, cb)  {
        this.state.counter = this.state.counter + inc;
        if (some error condition) {
            cb("got error");    
        } else {
            ...
        }
    }

Even though we have modified the counter, the framework forgets about those changes when there is an error, and both the checkpoint and the next request will see the old value of the counter. The "got error" string will be returned with an application-level error to the client, as we will see next.

What about exceptions?

Exceptions also rollback changes, but they are assumed to be a programming error, and your client will get a system error (exceptionThrown). Do **not** throw exceptions to propagate application errors.


### Client 

The main Enyo app file is in `public/source/App.js`. You could also use a `node.js` client (see `caf_lib/caf_cli`) and a jQuery plugin will be next. The user interface for this example should be very simple, let's look at the CA-specific bits: 

    {kind: "ca.LoginContext", name : "login", onSession : "newSession"},
    ...
      {kind: "onyx.Button", name : "myButton", content: "inc", ontap: "callCA"},
    ...
    newSession: function(inSource, inEvent) {
        this.mySession = inEvent.session;
        return true;
    },
    ...
    callCA: function(inSource, inEvent) {
        var self = this;
        var cbOK = function(msg) {
            self.$.lastcall.setContent(JSON.stringify(msg));
        };
        var cbError = function(error) {
            self.$.lastcall.setContent('ERROR:' + JSON.stringify(error));
        };
        this.mySession && this.mySession.remoteInvoke('increment',[1],
                                                       cbOK, cbError);
        return true;
    },
    
    
We first create a LoginContext that will negotiate a session with the CA (see file `caf_core/public/source/util/LoginContext.js` for details). When we have a new session  the event `onSession` triggers the handler method `newSession`, which registers the session. At any time we can tap on the button `inc` to call method `callCA`, and this method will invoke the method `increment` in the remote CA with argument `1`. When the CA responds either one of the callbacks will be called (error or last counter value) changing the display accordingly. 


  
## <a id="pulse"></a>Tutorial 1b) Adding autonomous behavior with pulse

We would like to guarantee that a CA increments its counter regularly. Even if nobody is calling its public methods.

We can easily do that by providing a `__ca_pulse__` framework method:

    '__ca_pulse__' : function(cb) {
        this.state.counter = this.state.counter + 1;
        cb(null);
    }
  
CAF periodically calls that method for each CA.  

### Configuration

How often does the framework call the CA? 

We can configure it, like almost any other property in the framework, by modifying the file `lib/framework.json`. In particular, if we want a call  every 3 seconds, simply set the interval property to 3: 

    {
        "module": "cron_pulser",
        "name": "pulser",
        "description": "Cron job for enabling autonomous computation of CAs",
            "env": {
                "interval" : 3 
            }
        }
    }

This configuration file may look a bit cryptic but it should not be. The framework is built from components, and each component has four important attributes: 

* `"module"` specifies the code that implements that component, we use standard node.js modules, so you could think of this as the string you would pass to a `require()` call to load a module (not exactly, see below for details)
* `"name"` the identifier in the framework-level context that this component will get after creation. Components are not tightly bound to each other, they look themselves up in the context before invoking methods on each other. We use conventions  of what the `"name"` of a particular component should be and this makes it easier to swap implementations. In fact, you could change the implementation of almost anything by modifying `lib/framework.json`.
* `"description"` JSON does not support comments so it is handy to have a placeholder for them. They are also visible at run-time and this could make error reporting a bit cleaner.
* `"env"` a bunch of properties that are passed to the component at creation time. By convention, all crons (components performing regular tasks) use the identifier `"interval"` to define time in seconds between actions.

Similar to the framework, a CA is built from pluggable components. The config file `lib/ca.json` plays the same role as `lib/framework.json`, but for a single CA.

#### Default configuration

Example 1a did not define an `"interval"` property in `lib/framework.json` for `cron_pulser`, so it inherits the framework default value.

Where is the default value for `"interval"` defined?

Components in `lib/framework.json` nest. In the code, at the top level, you see a `"sup"` component with an `env` that sets interval to 5. If a child component does not define its own `interval` it gets its parent. 


When we start the framework we pass two arguments, the first one sets a default directory for `*.json` config files (`__dirname` is set by node.js to the directory containing the `lib/ca_methods.js` file). The second argument passes an object with properties that will first overwrite `"sup"`'s `"env"`. This is convenient for passing  environment properties at run-time.  

For example, a child component of `"sup"` that does not define its own `"interval"` will get a value 7:

    caf.init(__dirname, {"interval": 7});
    

## <a id="notif"></a>Tutorial 1c) Asynchronous client notifications

Autonomous behavior is useful but it is better when we can notify the client that something happened as a result of that autonomous computation, and it is even more useful if that notification is buffered in the cloud until the client is ready to see it.

We use a simple example to illustrate this. When the counter is multiple of 5 we will notify the client of that event. The modified code for `__ca_pulse_` is below, changes for the `increment` method are similar:

    '__ca_pulse__' : function(cb) {
        this.state.counter = this.state.counter + 1;
        if (this.state.counter % 5 == 0) {
            this.$.session.notify([this.state.counter], 'default');
        }
        cb(null);
    }


### this.$

We try to make it really easy to safely support multi-tenancy in your application, and one way to do that is by restricting visibility to the framework internals. 

When the CA is created, `this.$` gets populated with proxies to all the services accessible from your methods. Proxies add authenticated client information to all requests, making it easier to enforce separation.

The contents of `this.$` are whatever it says in `lib/ca.json`. For example, to send notifications we need a proxy to the session service of this CA:

    "proxies" : [
          ....
          {
            "module": "caf_session/proxy",
            "name": "session",
            "description": "Provides information of the session of this incoming request",
            "env" : {

            }
        },
        ...
    ]

Take a look at the core file  `proxy_session.js` in `caf_lib/caf_session/lib`, and you can see that it exports a method `notify(argsArray, sessionId)`, which queues a notification containing an array with arguments, and this notification is delivered within the specified `default` logical session. You can find details about logical sessions in Tutorial 1d.

### Errors

What happens if we return an error after calling the method `notify`? 

The session service is transactional. Since it participates in the overall method transaction, it aborts too (think two-phase commit), so the notification gets ignored. 

The ability to add more (local) services participating in the transaction by modifying `lib/ca.json` is one of the most powerful features of the framework. Transactional services piggyback on the checkpoint mechanism to ensure durability, so we do not use distributed transactions in case you are wondering... 

### Client

When it receives a notification from the CA, the client code emits an (Enyo) event. 

For example:

    {kind: "ca.LoginContext", name : "login", onSession : "newSession",
        onNotification: "newNotif" },
     ...     
     newNotif: function(inSource, inEvent) {
         var counter = inEvent[0];
         this.$.notification.setValue(" got counter " + counter);
         return true;
     }

Event `onNotification` is handled by method  `newNotif` that  extracts the counter from the array of arguments in the notification, and changes the display.

Note that `LoginContext` above does not specify a logical session, and it will default to one named `default`, matching the name used by the CA.


## <a id="logical"></a>Tutorial 1d) Managing client notifications

The previous example had two serious issues: 

* the logical session `default` could be shared by several client devices active at the same time, and each notification will only appear in one of them, picked at random
* when no clients are active the CA queues notifications until it runs out of memory

In order to fix these problems we allow a CA to have multiple independent logical sessions, and also allow your code access to the output queues associated with them. 


### Logical sessions

A client chooses any name for a session with its CA. This name can be shared by multiple clients. All the sessions with a CA using the same name form a logical session. A CA views a logical session  as a named output queue from which any client using a session with the same name can dequeue notifications.

This gives you flexibility on how to deliver notifications to clients. You can associate a different logical session to each device; and then the CA can choose the device that will receive the notification, or  send the same notification to all of them.

For example:

    var DIVIDER = 5;
    var notifyAll = function(self) {    
        if (self.state.counter % DIVIDER === 0) {
            for (var sessionId in self.state.logicalSessions) {
                self.$.session.notify([self.state.counter], sessionId);
            }
        }
    };
    ...
    '__ca_pulse__' : function(cb) {
        this.state.counter = this.state.counter + 1;
        notifyAll(this);
        cb(null);
    }

Here we just maintain an object with the logical sessions to which we want to send notifications, and we repeat the `notify` operation for each one. 

As an optimization, we can track logical sessions that have been active recently and just notify those. We do that by querying the active logical session inside the `increment` method and use this info to populate a small LRU (Least Recently Used) cache from which the set of logical sessions  is derived. See `ca_methods.js` for details.

The client code specifies the name of the session by using the `sessionId` property:

    this.createComponent({kind: "ca.LoginContext", 
                          name : "login", sessionId :this.getSessionId(),
                          onSession : "newSession",
                          onNotification: "newNotif" }),
  
and we dynamically create the `LoginContext` because we need to wait for the user typing the session name.

### Output queues

We need to limit the size of output queues to avoid running out of memory. The best strategy is very dependent on the application. A CA can ignore a new notification based on its output queues' contents; or it can  make room by dropping older notifications.

For example, let's ensure that the queue has no more than 10 notifications (the most recent ones):

    var DIVIDER = 5;
    var MAX_NUM_NOTIF = 10;
    var notifyAll = function(self) {    
        if (self.state.counter % DIVIDER === 0) {
            for (var sessionId in self.state.logicalSessions) {
                 self.$.session.boundQueue(MAX_NUM_NOTIF, sessionId);
                 self.$.session.notify([self.state.counter], sessionId);
            }
        }
    };


The `boundQueue` method takes two arguments:
 
* the minimum number of notifications that, if available, we should leave in the queue after dequeuing
* the session name


Another useful method in `this.$.session` is `outq(sessionId)`; `outq` gives you a read-only snapshot of the output queue (using an array-like data structure). 


Note that changes to output queues are not serialized with respect to CA method invocations, and we should not rely on the output queue staying the same by the time we commit method changes. That's why `outq` returns a read-only snapshot and we need the method `boundQueue` to modify the queue. 

## <a id="service"></a>Tutorial 1e) Enabling interactions between CAs with a service

A CA is a light-weight proxy and whenever it feels like it is doing too much, you should think about off-loading the work to a service and using a plugin for access. In the directory `caf_extra` we have a few plugins that enable CA interaction with services. 

Once the plugin has been written, using it is easy. However, writing plug-ins can become complex, especially when they need to preserve transaction semantics. At the time of this writing CAF internals are still unstable, which doesn't help. We do not want to discourage you from giving it a try, but you have been warned! 

Most plugins have three components: 

* a proxy that will be visible to your code in `this.$`, 
* a hidden component associated with a CA, usually stateful, that we call `plug_ca`,
* and a framework-level component, usually stateless, that multiplexes all the interactions of the local `plug_ca` components in a few connections to the service (`plug`). 

In this example we use Redis (http://redis.io) underneath to implement a publish-subscribe messaging abstraction that allows CAs to inform each other when their counters reach specified thresholds. Our plugin will have:

* a proxy called `pubsub` where you'll find the publish and subscribe methods for the CA, 
* a `plug_ca` that maintains the list of channels to which your CA is subscribed,
* and a `plug` that keeps alive a few connections to the Redis server to support all the local channels.

In order to use the publish-subscribe service we have to add the `plug` to `framework.json` (since it is a framework-level component) and both `plug_ca` and the proxy to `ca.json` (you get new ones when you create a CA).

    // in framework.json inside "plugs"
    {
        "module": "caf_pubsub/plug",
        "name": "pubsub_mux",
        "description": "Shared connection to a pub/sub service \n Properties: \n",
        "env": {
        }
     },     
     
    // in ca.json inside "internal"
    {
        "module": "caf_pubsub/plug_ca",
        "name": "pubsub_ca",
        "description": "Provides a publish/subscription service for this CA",
        "env" : {
        }
    },

    // in ca.json inside "proxies"
    {
            "module": "caf_pubsub/proxy",
            "name": "pubsub",
            "description": "Access to a publish subscribe service\n Properties:\n <insecureChannelPrefix> Name prefix for channels that are not authenticated.\n",
            "env" : {
                "insecureChannelPrefix" : "anybody/"
            }
        },
    },

We use a hierarchical notation for the `module` because we wrap the three components into a single node.js package (`caf_pubsub`). By convention, a package that implements a plugin exports `plug`, `plug_ca` and `proxy` methods with its corresponding modules.


By default the plug-in `caf_pubsub` only allows a CA to publish on channels with names prefixed by its own identifier, and this helps to support multi-tenancy safely. To override this behavior we reserve a channel prefix for non-authenticated channels, i.e., `insecureChannelPrefix`.

    var CHANNEL_NAME = "anybody/tutorial1e:counterchannel";
    ...
    "__ca_init__" : function(cb) {
        this.state.counter = -1;
        this.state.finished = {};
        this.$.pubsub.subscribe(CHANNEL_NAME, "thresholdHandler");
        cb(null);
    },
    
    '__ca_pulse__' : function(cb) {
        this.state.counter = this.state.counter + 1;
        if (this.state.counter >= MAX_COUNTER) {
            this.$.pubsub.publish(CHANNEL_NAME, this.$.session.getMyId());
        }

        var nFinished = Object.keys(this.state.finished).length;
        if (nFinished >= MAX_FINISHED) {
            this.$.session.notify([nFinished], 'default');
        }
        cb(null);
    }, 
    
    //handler method
    "thresholdHandler" : function(channel, id, cb) {
        this.state.finished[id] = true;
        cb(null);
    },



In the example above, each CA subscribes to the same non-authenticated channel. When a counter reaches a specified threshold, its CA publishes this event using its unique CA identifier. Then, each CA gets to see this event and updates its own set of the CAs that have reached the threshold. To take care of the fact that publishing an event is a best-effort operation, CAs that have reached the threshold regularly re-announce that fact. 

When a CA learns that a pre-specified number of CAs have reached the threshold, it queues a notification to its own client. 

The method `subscribe(channel, methodHandler)` informs the plugin of the method in this CA that handles a published message. Internally, the plugin translates a Redis/node.js event into a local message that will invoke that same method. 

This allows us to continue processing requests while ensuring that asynchronous event handlers **don't** create race conditions. The execution of the handler method is serialized with respect to other requests because the CA treats events like any other request. 

As we discussed in [CAF Design](framework.html), do not try to handle node.js events directly in your methods, instead you should enforce serialization of handlers with an actor (i.e., a CA) to keep sane.   
     

