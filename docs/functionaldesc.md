# Cloud Assistant Framework 

CAF is a component-based JavaScript framework supporting dependency injection.
Components are described using JSON descriptions. Both the framework and the CAs created by it are assembled from components.

CAF components implement a simple Actor model in Javascript to provide a cheap, scalable, active, persistent presence to a web app. A CA is an actor that has a unique URL, an input message queue, some state that is transactionally managed, and the ability to interact with the external world by using plug-ins.

The  proposed open source code is organized in four sections: core, libs, extra, and examples.


## 1. Core

The core provides a hierarchy of basic components, and a bootstrapping loader for them.  Components include a supervisor, plugs to interact with external services (or locally created ones), crons to repeatedly perform certain tasks, and a message processing pipeline.

A created CA uses the same hierarchy of basic components but it provides a new top level component that is not based on the framework supervisor, creating an independent scope for its own components.


### 1.1 Main/Loader

Initializes the system and uses standard CommonJS modules (and npm packages) to load the implementation of other components. 

### 1.2 Supervisor

Top level component that maintains a framework-level context and manages other framework components.

### 1.3 CA container

Top level component per CA that creates a CA-level context independent from the supervisor (or other CA) context. The CA container gets populated with proxies that mediate access to other services from application code. 

### 1.4 Plugs

Plugs are interfaces to external services or local ones. Typically, a local service is implemented by the plug itself, but this should be invisible to clients. 

#### 1.4.1 Checkpointing

CAF checkpoints in a remote service the state of a CA before performing any action that could make that new state externally visible. This plug uses a backend Redis service to provide this service.

#### 1.4.2 Cloud Foundry 

Integrates with the underlying PaaS (Cloud Foundry) system to obtain configuration information at run-time. 

#### 1.4.3 CA Factory

Local service to create new CAs by assembling components from a description. 


#### 1.4.4 Lookup

Uses a CA's unique name to find a reference to it. It transparently removes shutdown CAs from the directory.

#### 1.4.5 Dispatcher

Forwards requests to a target CA and propagates responses back to the client.


### 1.5 Crons

Crons perform  bookkeeping tasks for the framework in a timely manner. 

#### 1.5.1 Lease Manager

To ensure that there is only one active representation of a CA in the data center we use a lease-based mechanism. A lease is just a binding of a CA unique name to the host/port of the node.js process that is actually hosting that CA. The lease manager periodically renews leases before they expire for all the local CAs that are in good health. This ensures that after a failure, affected CA's leases will expire, enabling the safe relocation of those CAs to other nodes.  

Leases are implemented with an external, data-center wide (Redis) service.


#### 1.5.2 Pulser

Enables autonomous behavior for CAs, even when they are not processing client messages, by regularly sending them a pulse message.

#### 1.5.3 Ripper

Detects hanged CAs by periodically examining their input message queues, and shuts them down.

#### 1.5.4 Security

Enables background security tasks, such as cleaning up authentication caches.


### 1.6 Processing Pipeline

Messages targeting CAs are encapsulated in HTTP requests and processed in a series of steps until they are forwarded to the target CA. We use a processing pipeline based on Express/Connect that provides security checks, performance profiling, dispatching, request redirection, error handling, and so on...  

## 2. Libraries

### 2.1 Enyo Client 

An Enyo library that a client application can use to send messages to CAs or handle notifications from them.

### 2.2 Node.js Client

Ditto but when the client application is written in node.js.

### 2.3 Session

Enhances the actor model with multiple output queues for handling asynchronous CA notifications. These queues can be easily manipulated by application code, to match the propagation and buffering needs of any app.

It also leverages the checkpointing mechanisms to provide 'exactly-once' request processing guarantees for stateless clients.


### 2.4 Sharing

Extends the actor model with an efficient mechanism to share mostly read data among actors. It leverages the transactional mechanisms that CAF uses to process messages to enable emulation in the basic actor model.

### 2.5 Security

Implements authentication and authorization checks for CAF. Authentication is token based, and attenuated, allowing safe interactions with less trusted applications. Authorization uses a naming scheme based on linked local name spaces to implement delegation with access control lists. The underlying implementation can use the sharing abstractions above.  


### 2.6 Profiler

Performance monitoring of CA requests. Request latency, queue length and request throughput.

## 3. Extra

Support functionality for the examples, not production quality code.

### 3.1 Deploy

Plug-in to enable a CA to deploy other applications in a Cloud Foundry system.

### 3.2 Imap

Plug-in to interact with an e-mail service using the imap protocol.

### 3.3 PubSub

Plug-in to implement a publish subscribe bus for CAs using Redis.


### 3.4 Pull
Plug-in to monitor changes to the contents of a URL and cache them locally.

### 3.5 Simulator

An HTTP-based proxy that enables  running the framework  locally for debugging purposes.


## 4. Examples

Simple examples, some part of a step by step tutorial, totaling 18 so far.
They expose most of the functionality described above. 
