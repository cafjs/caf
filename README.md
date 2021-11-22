# Caf.js

<a href="https://www.cafjslabs.com"><img src="https://raw.githubusercontent.com/cafjs/caf/master/assets/logosquare.svg?sanitize=true" alt="Caf.js" width="200"></a>

Co-design cloud assistants with your web app and IoT devices.

[Website](http://www.cafjslabs.com) |
[Documentation](https://www.cafjslabs.com/docs/documentation) |
[Installation Guide](https://www.cafjslabs.com/docs/documentation#install) |
[Caf.js Cloud](https://root-launcher.cafjs.com) |
[Twitter](https://twitter.com/cafjs)


[![Build Status](https://github.com/cafjs/caf/actions/workflows/push.yml/badge.svg)](https://github.com/cafjs/caf/actions/workflows/push.yml)

## Overview

A Cloud Assistant (CA) has

* some private and reliable state,
* a public URL that exposes authenticated methods,
* a queue that serializes requests, eliminating races,
* and the ability to run autonomously for years with minimal cost (85 cents per year, Gold plan [Caf.js Cloud](https://www.cafjslabs.com/hosting)).

CAs are implemented with the Actor Model.

A billion CAs can be hosted with a few thousand servers. Every IoT device or Web App instance could have one. Why do you want one?

#### Permanent Presence

Devices and app instances are sometimes off-line, or hard to reach behind a firewall, or suffer from long or unpredictable network latencies.

This makes it very difficult to share them safely across the Internet, or integrate them in VR or AR using an avatar.

A CA solves the connectivity problem by implementing a Reverse Service Worker (RSW), which represents the device or app instance at all times.

#### Proactive Programming

We all have heard of reactive programming, where your code process a stream of events.

The dual to reactive is proactive. Compute without waiting for an event to arrive.

What can you do with proactive programming?

* Hide latency with a push model, as in PSSR (Proactive Server Side Rendering),
* or create a GraphQL subscription source from legacy services,
* or upload background tasks to the Cloud with cloud-based multi-tasking.

#### Reliable Orchestration

Jamstack is all the rage, but the reality is that you still need a backend to orchestrate service API calls, because doing that in the browser is unreliable and not very safe.

Micro-services are all the rage, but now the complexity has been shifted to tracking requests among thousands of micro-services. If something fails, can you safely retry? If the state is distributed across many micro-services, who is responsible to clean up the mess?

You can view a CA as a reliable state machine, which always checkpoints before externalizing state changes. Or a smart card for your API credentials. Or a reverse proxy that caches dynamic content, keeping your clients in sync.

#### Collaborative Multi-Tenancy

CAs interact with each other safely using the trusted bus. High level communication primitives ensure that these interactions scale to millions. Fast datacenter networks provide predictable low latency.

When devices or apps want to interact, they can use their CAs to guarantee secure, scalable, and fast communication. This gives them superpowers:

* Coordinate actions with global time on millions of devices across the World,
* or bootstrap trust between strangers,
* or control thousands of Web App Backgrounds (WABs) in your next Zoom-like meeting,
* or provide a twitter-like service for devices with a hundred lines of Javascript.


But this is just the tip of the iceberg of what CAs can do. Learn more in our [website](https://www.cafjslabs.com)


## About this repo

This repository is managed as a monorepo using yarn workspaces. It contains a consistent snapshot of all the other `Caf.js` sub-projects, included as git submodules. To create a `Caf.js` release, we test them all together.

It is recommended that you create your app within this monorepo, in a subdirectory of `caf/playground/app`, and then yarn workspaces will also manage your app dependencies.

Ditto with your modules. Just create them under `caf/playground` and they are part of the common workspace. No need to publish them during development!

## Install

Install `node` LTS >=12 and `yarn` >=1.3.2. Our development is mostly on Linux. Note that `npm` does not understand Yarn workspaces, you need to use `yarn`.

Clone this repository (`git clone https://github.com/cafjs/caf.git`) and update submodules:
```
    cd caf; git submodule update --init
```
Install all the dependencies (it takes about 30s in my laptop):
```
    yarn run installAll
```
add to your path the `cafjs` tool path:
```
    export PATH=<your_install_directory>/caf/bin:$PATH
```
download the Docker images
```
    cafjs update
```
and now let's build and run locally a simple app:
```
    cd apps/caf_helloworld; cafjs build; cafjs run helloworld
```

The app server URL is http://root-launcher.vcap.me (DNS always resolves `*.vcap.me` to `127.0.0.1`, i.e., the local loop). With your browser, login with user `foo` and password `bar`, and then click the `+` icon to add a `helloworld` CA. Fill the form as follows:

* Application publisher: `root`
* Application name: `helloworld`
* CA name: anything containing ASCII characters and numbers.

and a `counter` example should appear. Use the `+` again to create other CAs, and then select the menu on the top left to switch between them.

To stop it, a single `Control-C` will initiate a gentle container shutdown but, for the impatient, a second `Control-C` will brute force a clean-up.

In both cases we should be able to restart without losing the CA's state. This state is checkpointed using a Redis container that mounts a host volume (log file in `/tmp/redis/appendonly.aof`, host port 6380). To start from scratch, delete the log file in the host.

## Documentation

The Caf.js documentation is now in our  [website](https://www.cafjslabs.com/docs/documentation)


## Contributing

We welcome contributions to Caf.js of any kind. See [Contribution Guide](CONTRIBUTING.md) for details.
