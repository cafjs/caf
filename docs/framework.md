#  <a id="top"></a>CAF: Active, Co-designed Cloud Proxies for Everybody
#### Antonio Lain, HP Labs, Palo Alto

We have seen a few examples of pairing a web app instance to an active, permanent cloud proxy to solve really difficult integration problems. A key requirement for those solutions is that the behavior of the proxy has to be co-designed with the client application. 

This is what motivated our first requirement for CAF: the front-end app developer should also be able to implement the proxy. This is not common today, with separate front-end and back-end teams negotiating for weeks on low level Web APIs. 

One reason this happens is that the skill set of a front-end developer is very different from a back-end guy. The average front-end developer will be comfortable with JavaScript and an event loop model similar to the one the browser provides, but is likely to find it very challenging to deal with concurrency or with distributed system failures. 

To enable co-design we need to simplify the programming model.

We achieve that by restricting the scope of the model, even though too much simplification might end up disappointing experienced back-end developers. Yes, your app instance can only get one Cloud Assistant, and if you want to handle your own (node.js) events your way it will be painful. 

Even if you prefer more choices than CAF currently offers, please do keep reading. If you do not end up using CAF we still hope that some of the ideas will inspire you when building your own (or helping us out). 

### Erlang Lessons

Many mobile apps crash after a few minutes, so is it reasonable to expect the same 
developer to write a proxy that should be up for years? We say the answer is both yes and no. We've taken a lesson from Erlang [][#Armstrong:2007], which says crashing is a fact of life, and that we should detect failures asap, ensure no side effects, and deal with them at a different level. 

For example, if you've done something that causes your CA to produce an error while processing a request and the internal state is messed up; no worries, after returning the error to the caller we automatically restore its state to the last one that was externally visible and ignore other uncommitted delayed outputs. Nobody else will notice!

What happens if an app has serious issues and keeps crashing?

Apps are kept separate, so a node.js process could host thousands of CAs that are all from the same app, while all app to app interactions use external interfaces. This means that we can take recovery actions at the platform-level without affecting other apps.

The CA's long life implies that it will undergo numerous upgrades. We need to allow upgrades with minimal client disruption. Again, Erlang/OTP to the rescue. The CAF calls a 'resume' framework method in each CA after an upgrade but before processing any more messages. This method provides a checkpoint of the state that contains versioning information, and this gives a chance to the CA to safely upgrade its internal state if code and  checkpoint versions differ. Moreover, we package together the front-end and CA bits of
 your app (i.e., CAF is also a web server for your front-end) and that helps to
keep both consistent.


If you see a pattern here, it is not coincidental. Our first prototype of CAF was Erlang-based. But we quickly realized that the language would be an issue to front-end developers because they favor JavaScript. Node.js brings JavaScript to the 
server side, but it provides very low level programming abstractions out of the box. We decided on the generic server behavior from Erlang/OTP as the basis of our CA, and evolved it to fit a node.js implementation. It has a been a bit of a journey from there as you will soon see... 

### Cost

Nobody wants to pay for proxies. If hosting a CA costs only cents per year, that price can be included in the price of the app, or possibly hidden by other means. To keep the cost this low, a typical CA must be really light-weight. Think of a few kilobytes of state along with processing a simple message per second or less. All the heavy-lifting should be delegated to cloud services, leaving the CA as a simple state machine that mostly coordinates interactions and forwards messages. If you keep to these limits there is hope: even without any major efforts to optimize CAF, we can already host about 1K CAs with one Xeon core (or 250+ with a modern ARM core).


### Scale


The number of instances of browser-based web apps or devices in the Internet of Things could quickly exceed the billions of apps sold today through proprietary App Stores.  Popular mobile apps easily exceed a hundred million users, so scaling a single app is also an issue. 

As we mentioned above CAF multiplexes about 1K active CAs in one node.js process, and apps are kept separate from each other, meaning that they can be easily deployed in independent (or federated) platforms.

#### Scaling a single app 

Our Minimal Deployment Unit (MDU) for an app will host about a 100K CAs using a pair (i.e., master/slave) of Redis processes and a few hundred node.js processes. Redis is used for checkpointing private CA state. By partitioning CAs into MDUs we limit the number of connections per Redis process to a few hundred. However, we still have not solved the main problem, scaling CA to CA interactions across a few thousand MDUs. 
 
It is likely that we will not be able to exploit much locality,  and we will end up with a deadly all-to-all communication pattern. 

What shall we do about it? Well, our approach is simple, if you cannot scale it, don't do it. Don't use point to point communication between CAs, use instead distributed sharing abstractions (see below) or services. 

Isn't that just shifting the problem to someone else? Sort of,
the hope is that by providing higher level information of the interactions needed it will be easier to exploit fancy hardware or a custom algorithm. We will give you an example when we introduce Sharing Actors.


### Summary

It should be clear by now that CAF is not a general-purpose framework.
We simplify abstractions to allow co-design, we rely on off-loading most of the work to cloud services to keep hosting costs down, and we discourage point-to-point interactions to scale. 

So far we have mostly talked about things we don't do. 

Let's talk about what we actually do. 

* First, we argue why adding actors to node.js reduces programming complexity. 
* Second, we introduce persistent sessions by adding explicit output queues to an actor. 
* Third, we provide a novel data (and code!) sharing mechanism for actors that solves the 'mostly-read by many' inefficiencies of a traditional Actor model without changing actor core semantics (aka Sharing Actors). 
* Fourth, we put these sharing abstractions to good use in CAF's security model where they represent local name spaces that are linked and replicated. 
* Finally, in CAF both a CA and the framework itself are built from components, and we show how to customize those components using dependency injection.


## <a id="actors"></a>Actors in JavaScript

At the beginning we naively thought that the event loop in node.js would be similar enough to the event loop in the browser so that front-end programmers could just feel at home. Replace UI events with messages and you are done. Right? Not quite. 


### Races in JavaScript

Races in JavaScript? JavaScript is single threaded, so why are we concerned?

Well, there are no data races in a shared-memory sense (two+ concurrent accesses to a memory location, one of them a write) but node.js uses an asynchronous execution model in which a task is implemented as a sequence of simpler asynchronous steps, and these steps could interleave with the steps of another task in an arbitrary manner. 

Since all these steps could modify the same state, they could  affect each other. For example, a step can break an invariant that another step in a different task depends on. 

So we do have to worry about coarse-grained races.

#### Race example

A file-based log service implements two tasks: *Append* and *Rotate*. *Append* has one asynchronous step that writes data to the log file. *Rotate* has two asynchronous steps: the first one (*Copy*) copies the file to another one with a new extension; the second one, (*Truncate*) truncates the log file to have zero size. When we execute an *Append* after a *Copy* but before a *Truncate* both tasks give no errors but the newly appended data is missing. 


#### Front-end programming and races

Coarse-grained races are not as common while programming an application front-end. Typically, you will get a UI event, modify the DOM, and you are done. You do not tend to spawn a sequence of asynchronous steps to process a UI event. 
And even when you do, e.g., while using AJAX calls, the user and the application logic tend to help you to serialize correctly those steps. 

Front-end programmers  need a higher level abstraction than node.js that transparently deals with coarse-grained races.

#### First attempt to eliminate races

A simple solution is to add a task queue. As long as we let every task finish before dequeuing the next one, all the asynchronous steps in a task are serialized. In the previous example, an *Append* task will  start before (or after) the *Rotate* task and their steps never interleave.

Unfortunately, using a single task queue can seriously degrade performance.
Assume that each CA has its own log and we want to support a large number of CAs with a single (node.js) process. Even though we could safely overlap a *Rotate* task in one CA and an *Append* one in a different CA they are unnecessarily serialized by the queue. Disks perform better with multiple outstanding IO requests and also, it is easier to minimize perceived latency by prioritizing short (but frequent) *Append*  tasks.

#### Eliminating races with actors 

We need more task queues, but tasks in different queues should not interfere with each other while operating independently.

One way to provide that guarantee is ensuring that tasks in different queues do not share state. In CAF each CA has its own task queue and some private state, with no access to global state. 

Now, if you think of a message as a way to encapsulate a task, you can see that a CA is just a simple actor (in the Actor model sense [][#Agha:1985]), that has a global name and some private state, serializes message processing from an input queue, and communicates asynchronously with the external world.


### Error recovery with actors

The second big difference between front-end and back-end programming is how to deal with application errors or system failures. The front-end has the luxury of having a human involved that kindly (or reluctantly) will take a meaningful recovery action (like flushing the phone down the toilet). Also, expectations are lower, and an application crash is tolerated, even with lost of your data, if it does not become part of your daily routine. 

In contrast, the proxy in the cloud should be invisible to the end user; it just works, for years at a time, while gracefully recovering from hardware failures, botched code upgrades, or the occasional infrequent software bug. By giving a bit of stability to your app with a CA, it will also help the end user to make the right meaningful recovery action when the front-end crashes while minimizing data loss (and flushed phones).

It is difficult to transparently recover a task that involves multiple asynchronous steps from arbitrary failures. We are not claiming that CAF gets it right all the time, it just tries harder.

The CAF approach is based on two old ideas: 

* keeping in a remote checkpointing service a snapshot of the CA's state right after the last completed task
* delaying unrecoverable (external) actions until the last minute and then committing them atomically using a local two-phase protocol (checkpointing also makes this commitment durable).

When we get an error, or the underlying platform recovers from a hardware failure, we load the snapshot, update the CA state and redo all the committed actions (assumed idempotent).

#### Limitations

What if committed actions are not idempotent?

Transactional actions are implemented using a plug-in, and the assumption is that this plug-in knows how to make the action idempotent. For example, it could implement a reliable messaging transport that gives unique identifiers to messages and eliminates duplicates, or it could use a distributed transactional protocol like XA, or it could just check that an action has not been executed before retrying. 

Note that the main reason for a local two-phase commit protocol is to orchestrate commit for multiple plugins, since a CA may have a task committing resources with very different requirements.  

Our approach fails when progress of an intermediate asynchronous step requires an unrecoverable action. CAF does not put restrictions on your node.js code, and it is actually easy to end up in such a situation. 

In many cases the root cause is that the scope of the task does not match its natural transaction boundaries, and promoting several steps to independent tasks fixes the problem. In other cases reordering steps helps. When all bets are off you will end up in the ugly world of compensating actions, possibly with the help of a plug-in.

All this sounds complicated, are we really simplifying the programming model?

We are shifting complexity from the CA writer to the plug-in writer. A transactional plug-in is, in most cases, written by a back-end expert, not by a front-end programmer.

As long as the CA writer manages CA state and external interactions with core CAF mechanisms or transactional plug-ins, he/she can ignore most of the previous discussion. The CA method abstraction, as described  in [Getting Started](gettingstarted.html), adds an argument with a callback  to notify the framework when to commit or abort the transaction. The expectation is that this callback is the last operation in the task, and also returns a response to the client.       

##  <a id="sessions"></a>Persistent Sessions

### Handling notifications

An autonomous CA can asynchronously notify the client application when certain condition occurs. Compared to CAs, the client is rarely on-line, and when is online it can access the CA from different devices, sometimes using multiple devices at the same time. 

This raises the question of what to do with notifications. Delivery of notifications is best-effort, but is not acceptable for many applications to drop all of them whenever the client is not on-line. We need to buffer them in the cloud.

But we cannot just keep buffering notifications until we run out of memory, and it is not always clear what to do when we need to drop some of them. Shall we get rid of the oldest one? Can we remove duplicates?  Can we just stop adding notifications until the client catches up? The right answer is very application-dependent.

Concurrent access to a CA from multiple devices raises similar issues. Shall we multicast the notification to all the devices? Is a first-come-first-served strategy acceptable? Can we target a particular device to receive certain types of notifications? Again, the right answer is very application-dependent. 

### Logical sessions

We need a simple software abstraction to customize notification handling. In a coup of originality we call that abstraction a session. A CA can have multiple sessions, each identified by a name. To talk with a CA the client first establishes a session with it while providing the name of the session (or 'default'). Similarly, when the CA wants to notify the client it also specifies the session name. 

We introduce the concept of a logical session to represent all the sessions that use a given name and target the same CA. All the notifications in a logical session are  randomly split across all the concurrent sessions with the same name. 

This gives you the flexibility that you need: for example, pick a different session name for each device and decide which one to notify. We provide examples in [Getting Started](gettingstarted.html).

### Output queues

A CA has an output notification queue for each logical session. The CA's application code can obtain the name of the current session and change its behavior accordingly. Moreover, the contents of that queue are directly accessible to application code with a simple interface (see  [Getting Started](gettingstarted.html#logical)). 

This gives to your code  full control of notifications but there is a caveat. 

As we mentioned a CA is an actor that serializes the processing of messages, which changes its internal state. We could have made output queues part of the internal state of a CA but in that case the client would not be able to dequeue a notification while the CA was busy processing a message. 

Instead, output queues are logically separate entities (i.e., a different actor) and they asynchronously communicate with both the client and the CA. This means that dequeue operations  by the client are concurrent with CA efforts to manage the queue. The queue management interface, as shown in [Getting Started](gettingstarted.html#logical)), restricts operations to gracefully deal with those races.


### 'Exactly-once' request processing

We also use sessions to support 'exactly-once' processing of client requests by a CA. 

The core ideas are based on [][#Bernstein:1990], that shows how a stateless client can achieve such property with the help of transactional queues. In their approach, stateless clients piggy-back information about its own state to requests, and this enables a safe recovery after client failure by examining the (transactional) queues that propagate requests (or responses). 

Why is this useful? Imagine that you are trying to buy a toaster with your favorite app. You type your credit card number, click ok, and then the app crashes. You restart the app and there is no trace of your order anywhere in the system. Confidently, you repeat the process and this time it works. Congratulations, you got two toasters!

It is difficult to get that right. Aggressive caching of stale data, delayed updates to the database, a long queue to process payments, partially cancelled requests... What you see now is not what you are going to get.

A CA can help. It serializes the processing of client requests. It also has some reliable state that is transactionally updated with a request.  And those requests are always part of a session, making it easier for a client to associate to a session part of its own state, which will be transactionally committed with the processing of a request. 

The protocol is straightforward. As part of the request the client could add a memento that will be remembered by the CA (as part of its checkpointed state) if the request commits. This memento is associated with the logical session of the request, and replaces any previous memento in that logical session. 

We also introduce explicit requests to start and close a session with a CA: the response to a start request is the last memento, and closing a session deletes the memento.  This allows a client  to detect an orphaned session, i.e., not properly closed due to a failure, when it starts a new one. It also ensures that the memento returned reflects its own state before the last properly committed request, and using that information it can accurately avoid re-issuing the same request (or missing one). 

The CA will delay processing the request to start a new session until all previous requests have been committed (or aborted), giving an accurate picture of the state of the back-end. See the example *JustOnce* for details.

#### Assumptions

There are some limitations. A stateless client can never remember whether it  processed a response before crashing, therefore, the client can only guarantee 'at-least-once' processing of responses. This is less of an issue in practice, humans are good at filtering duplicates, and, for example, are not likely to be surprised by seeing a confirmation page twice. 

Also, clients should be well-behaved, restarting a session when a request timed out as opposed to just retry the request, ensuring a strict sequence of mementos per logical session, and using mementos that uniquely identify what they should do next.  


##  <a id="sharing"></a>Sharing Actors

### Background

Actors have a fundamental weakness. Sharing mostly-read data across a large number of actors is inefficient and can cause problems when scaled. There have been two bad options available: 

*  Pick one actor, make the mostly-read data part of its internal state, and force the others to send messages to it when they want to access this data.

* Replicate the data in all the actors, pick one actor to serialize updates and propagate them.

Implementations that make use of the actor model generally  combine the above two options in some way, and then reduce the time to propagate updates by assembling a hierarchy of actors. This solves some, but not all, problems. The first option adds unnecessary serialization and forces an expensive message processing step per read. Plus, to maintain task atomicity, reader actors delay any additional message processing while waiting for a read, which results in performance degradation. The second option also has some undesirable results because the number of update messages and the memory overhead grow linearly with the number of readers. 

With our aggressive scaling goals, these approaches alone will not work well. So, we considered several alternatives.

Some actor frameworks, such as  Erlang, provide a back-door to access shared memory. Actors in the same process can then use an unsafe data structure (ETS table) to avoid local replication and reduce the number of updates. However, once you start using it, many bugbears of shared-memory programming are back, including races while updating multiple keys or lack of failure isolation. Too high a price to pay for the performance benefit.

Erlang also has Mnesia, a distributed, in-memory data store that tames unsafe data structures (ETS tables) by providing strong consistency and a transactional interface. The problem with Mnesia is that strong consistency limits scalability. A writer is blocked by readers, and when you have readers spread across thousands of processes, the coordination effort becomes unmanageable.

### Introducing Sharing Actors

The idea behind Sharing Actors is to identify a useful data sharing pattern, provide an efficient implementation, and ensure that the implementation can be emulated with actors that just use messages and internal state. 

Emulation preserves the semantics of actors, and, if you ignore performance differences, an external observer will not be able to tell whether we are using our fancy sharing implementation or just plain actor messages. This guarantees that the sharing implementation does not introduce any shared-memory bugbears. 

**Are Sharing Actors too good to be true?** 

This only works for certain data sharing patterns. It turns out that mostly-read data (one writer/many readers) is one of them. Shared data is owned by one actor, which views this data as part of its internal state. When it processes a message, all the changes to shared data during that processing are captured in a single update. We call that the **Atomicity** property. The propagation of updates preserves update order but it does not block writers. The result is that we can scale but we can only provide weak consistency.

Reader actors also treat shared data as (read-only) internal state. Changes to that state respect message serialization in that atomic updates cannot be visible during message processing. Otherwise, it would be impossible to emulate updates with messages. We call that the **Isolation** property.

We also need to provide fairness to enable emulation. A reader actor cannot delay indefinitely another actor from seeing a locally available update. We call that the **Fairness** property.

It turns out that a single-writer sharing implementation that respects the three properties of **Atomicity, Isolation,** and **Fairness** as described, can be emulated. The proof by Mohsen Lesani (UCLA) was constructive, giving us a direct translation into actors that is useful for debugging implementations. 

### Implementing Sharing Actors in CAF

Respecting both the *Isolation* and *Fairness* properties forces us to  locally maintain multiple versions of the shared data. This is easier to do efficiently with a higher-level data abstraction, and we use a Map interface. Internally, we implement this Map with a persistent data structure [][#Driscoll:1989] that is optimized to maintain a small number of versions very efficiently. We only need to maintain a few versions, because we refresh to the latest locally available version before the processing of each message.

Sharing Maps connect to the Spine, a distributed service that checkpoints master copies of Maps, facilitates discovery, and routes updates to replicas. The Spine is wrapped as a transactional CAF plugin to handle checkpointing and push changes according to the CAF failure recovery model that we described above. This hides most of the complexity of using Sharing Maps in CA application code. In fact, they just look like local maps. 

**Sharing Maps use Harmony proxies to implement JSON-serializable methods.**

We do not support closures, but the keyword *this* is properly bound to the Map, allowing a familiar object model. With it we can efficiently replicate both code and data across a distributed system and quickly perform updates that atomically change both. 

Moreover, the *Isolation* property guarantees that it is always safe to call these methods while processing a message, because code changes will respect message processing boundaries. Also, the *Fairness* property will ensure that eventually all CAs will upgrade. 

Let me give you a couple of examples where this is really useful (you can also see the Mutant example):

* Encapsulate data with accessor methods. If the internal structure of the data changes, the accessor methods change accordingly. Since both are atomically changed, you will never have to worry again about data versioning.

* Encapsulate an algorithm with some configuration data. Let's say that you want to instrument CAs to spy^H^H^H collect data on your customers. You could encapsulate what you collect and where to send it in a Sharing Map. When you change the algorithm or the service location, CAF will ensure that you always get valid data. Imagine if you could change the algorithm in a safe way to 100M customers in just a few milliseconds, what would you do with that? 

##  <a id="security"></a>Security and Linked Local Name Spaces

By the mid-90s consensus emerged that it was impractical to maintain a world-wide directory that maps meaningful unique names to public keys. An influential paper  by Rivest&Lampson [][#Rivest:1996] describing SDSI (Simple Distributed Security Infrastructure) advocated the opposite, manage your own local name space scoped by your public key. Local names are not globally unique but you can make them so by qualifying a local name with a (unique) public key. This enables unambiguous links to other name spaces. 

A local name in SDSI resolves to:

* A public key representing a principal.
* A link to a local name in another name space.
* A group containing some of the above.

If we keep on following those links and expanding groups we ended up with a set of public keys. To authorize a principal to access a resource check whether its public key is in the set, i.e., a local name is an implicit ACL (Access Control List). 

Or even better, associate a role with the local name, and use the previous strategy to determine whether a principal has that role. Then, use a compact ACL based on roles to authorize. 

Anybody can create a certificate stating what their own local names are bound to. No third-parties are needed to verify this certificate. No more thirty-something trusted root certificate authorities gambling with your security.

This is cool. It didn't take off. Why?

* Users do not want to manage private keys
* Finding the certificates that you need to access a resource is complex

Let's try this again. This time without managing private keys (or certificates)

### Naming resources in CAF

A user in CAF has a unique, not necessarily meaningful, name, for example:

* A verified e-mail address using a service like Mozilla Persona
* A login name in our Accounts service (unique only in the context of that service)
* A string-encoded hash of a public key (advanced users that  manage a private key)

When this user creates a CA, the name of this CA is always relative to the user's name, i.e., it is a local name in the name space scoped by the user's name. We use a reserved character '\_' to create a full name. For example, 'foo@bar.com' creates CA with local name 'ca1' and full name 'foo@bar.com\_ca1'.

We use a similar strategy when a user publishes an application. For example,
'otherfoo@otherbar.com' publishes the app 'myapp' with fullname 'otherfoo@otherbar.com\_myapp'.

In most cases we just care about interactions of CAs within the same application (see the introduction). CAF guarantees that full names are unique, and 'foo@bar.com\_ca1' will resolve to at most one CA. 

In some cases we need to identify a CA outside its application. Since users can reuse the same local name in different applications,  we need to qualify it with the application name. For example, 'otherfoo@otherbar.com\_myapp\_foo@bar.com\_ca1' represents a CA created by foo@bar.com when using the application published by otherfoo@otherbar.com.

Why is this naming scheme useful? CAF guarantees that a user cannot create objects in any name space but its own. This means that any application called 'otherfoo@otherbar.com\_\*' has been published by otherfoo@otherbar.com and any CA named  'foo@bar.com\_\*' is owned by foo@bar.com. If I can reliably obtain the name of something I know who is responsible for it.

And in CAF it is really easy to know the real name of something. Interactions between CAs propagate the  sender's name, and this name is added by security proxies that mediate all interactions. These security proxies are not trusted outside the domain of an application, but help the application writer to implement multi-tenancy for his app. Trust across applications is limited, as we will discuss later on.    

From our previous discussion, a Sharing Map has just one CA writer, and this gives us a natural naming scheme for Sharing Maps based on the name of their writers. For example, the Sharing Map 'map1' that can be written by CA 'foo@bar.com\_ca1' has a full name   'foo@bar.com\_ca1\_map1'. 

### No certificates needed in CAF

A CA 'speaks for' [][#Lampson:1992] the user that owns it in the restricted context of this CA's application. This means that other CAs in the same app will take actions by this CA as if they were performed directly by the user. 

To guarantee the origin of those actions, users can only establish sessions with CAs that they own. As part of establishing a session, a secure channel is created between the user and the CA. Our naming convention for CAs simplify user authentication for this channel: since a CA knows its name, it also knows its owner's name. 

Since a CA 'speaks for' its user, when this CA writes into a Sharing Map, the contents of this Map is an statement made by the user (valid only in the context of this application). CAF guarantees the authenticity of a Sharing Map, and readers of (read-only) replicas of that Map will treat that statement as if it were in a certificate signed by the user.


### Linking Sharing Maps

What all this has to do with SDSI and linked local name spaces?

We use a convention with Sharing Maps used for authorization. Keys in the map represent user names, values could be roles or permissions. We reserve one key for linking and the value of that key is a list containing the names of other Sharing Maps. In that context a Sharing Map is similar to a SDSI group but for convenience we have collected all the links in that group in a list. 

To maintain the collection of linked Sharing Maps we use a wrapper data structure called Aggregate. An Aggregate specifies a root map and maintains local replicas of all the maps that are reachable from that root using links. Looking up a key in the Aggregate will return an array containing the values of that key in any of the underlying maps. This makes it very easy to lookup all the roles associated with a user that are defined in any of the maps.   

Aggregates are fast. As we discussed, the replication mechanisms of Sharing Maps use shared memory to eliminate duplicates and they could use modern networking hardware more effectively. The lookup performance of a Sharing Map is just a bit slower than a property lookup in an object. Compare that to distributed searches and signature verifications of certificates in SDSI...

The *Atomicity*, *Isolation* and *Fairness* properties of Sharing Maps also help to make authorization more robust. Policy changes are atomic, they do not occur while we are processing a message, and they eventually propagate everywhere. This is an important issue that any  distributed authorization mechanism needs to address or would face failures due to inconsistent transient states, and we are getting a solution for free!


### Authentication with attenuated tokens

Not all CAF applications are equally trusted. When a user authenticates
to its CA in one of this less trusted applications, this CA could launch a 
 man-in-the-middle attack impersonating the user in another application (i.e., owned
 by the same user). At this point, the less trusted CA can take control of the 
 other CA and start 'speaking for' the user in the new application. Not good...
 
 We use attenuated tokens to avoid this problem. A user never authenticates with his own credentials to a CA. It gets redirected first to our 'Accounts' service and after login in with his credentials it gets a signed token (using the private key of 'Accounts'). This token can add extra restrictions on when it could be used for authenticating the user: 
 
 * Only before certain time
 * Only for applications published by X
 * Only for applications named Y
 * Only for a CA named Z

By adding all these restrictions to a token, a rogue CA will find that the token can only be used to authenticate to itself. 

This raises the issue of how to manage all these tokens. We can give a privileged token to a CA in a trusted application, and this CA can negotiate with the Accounts service on our behalf to obtain weaker tokens (or renew expired ones). An example of that is our Website application that implements single sign-on for all the launched applications and renews tokens transparently when needed. 

##  <a id="injection"></a>Dependency Injection

Both a CA and the framework  are assembled at run-time from components. What these components are, and how they are configured is described in  (JSON) configuration files. We use a simple convention to define the life-cycle of a hierarchy of components, and this makes it easier to add new components that extend the functionality of a CA or the framework itself.  

We copied this approach from SmartFrog [][#Goldsack:2009], a framework written in SmallTalk in the early 90s (and later on rewritten in Java), that used its own description language to specify the behavior of distributed component hierarchies.

We serialize the creation of components but we always use an asynchronous factory method to create them. Creation order follows description declaration order, and by choosing the right order we can enforce component dependencies. At shutdown we reverse that order to ensure no dangling references. 

Why an asynchronous constructor if creation order is fixed? 

* To support arbitrary (asynchronous) node.js library calls during component creation
* To ensure that we do not "stop the world" when we create a new CA

But asynchronous constructors are complex. It helps to isolate the bits that really need to be asynchronous, and we use two steps to create a component: first, call a hidden, synchronous constructor that builds the data structures (see files prefixed by 'gen_'); second, an asynchronous step that makes them live.  

Node.js has an amazing package manager (npm) and full support for CommonJS modules. We do not want to reinvent the wheel:

* Components in CAF are loaded as CommonJS modules, with module names specified in JSON descriptions
* Modules export a standard (asynchronous) factory method ('newInstance')
* A CAF component also needs to implement  a standard shutdown method. 
* Plugins to services typically have its own (node.js) package. We use a convention to identify the standard modules they need to implement.

More details on [Getting Started](gettingstarted.html).

How components find each other? We never use the global JavaScript context. Instead,  components register at creation time in a context that we pass as an argument to the factory method. They register with  a name specified in the JSON description, and we use conventions to specify those names. For example, the logger component always use the name 'log', and any other component can find the 'log' component in the context, and call the method 'error' to log an error. 

This allow us to swap the implementation of the logger by modifying a JSON config file.

Almost anything in CAF is implemented with a component, and this makes it very easy to change CAF behavior by modifying descriptions. The framework is also under the control of the application writer (as we mentioned, we do not mix applications in one framework process), and it is typically customized with one application in mind. For example, the framework only loads the  plugins to services that the application needs, or eliminates 'pulse' messages when no autonomous CAs are needed.


CAF uses several contexts to register components: A unique framework-level context, and two isolated contexts (internal and handler) per CA. We use the widely adopted JavaScript '$' naming convention for context when it is clear what context we are talking about. For example, application code only sees the handler context, and this context only has security proxies that use components in the internal context  of the same CA; only one context is visible and it is called '$'.
Similarly, inside the framework, since we only have one context to register framework components, we also refer to it as '$'. Hopefully, this is not too confusing...




[#Agha:1985]: Gul Agha. *ACTORS: A Model of Concurrent Computation in Distributed Systems*. PhD thesis, University of Michigan, 1985.

[#Armstrong:2007]: Joe Armstrong. *Programming Erlang: Software for a Concurrent World*. Pragmatic Bookshelf, 2007.

[#Bernstein:1990]: Philip A. Bernstein, Meichun Hsu, and Bruce Mann. *Implementing Recoverable Requests Using Queues*. In SIGMOD Conference'90, pages 112-122,
1990.

[#Goldsack:2009]: Patrick Goldsack, Julio Guijarro, Steve Loughran, Alistair Coles, Andrew Farrell, Antonio Lain, Paul Murray, and Peter Toft. *The SmartFrog Configuration Management Framework*. SIGOPS Oper. Syst. Rev., 43(1):16-25, 2009.

[#Lampson:1992]: B. Lampson, M. Abadi, M. Burrows, and E. Wobber. *Authentication in Distributed Systems: Theory and Practice*. ACM Transactions on Computer Systems (TOCS), 10(4):265-310, 1992.

[#Rivest:1996]: Ronald L. Rivest and Butler Lampson. *SDSI --A Simple Distributed Security Infrastructure*. Presented at CRYPTO'96.

[#Driscoll:1989]: J.R. Driscoll, N. Sarnak, D.D. Sleator, and R.E. Tarjan. *Making data structures persistent*. Journal of computer and system sciences, 38(1):86-124, 1989.
http://www.amazon.com/Douglas-Crockford/e/B002N3VYB6/ref=ntt_athr_dp_pel_1
