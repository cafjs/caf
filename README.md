# Caf.js

Co-design permanent, active, stateful, reliable cloud proxies with your web app and IoT devices.

See http://www.cafjs.com

## Introduction

[![Build Status](https://travis-ci.org/cafjs/caf.svg?branch=master)](https://travis-ci.org/cafjs/caf)

This repository is managed as a monorepo using Yarn workspaces. It contains a consistent snapshot of all the other `Caf.js` sub-projects, included as git submodules.

Write your app in a subdirectory of `caf/playground/app`, and yarn workspaces will also manage your app dependencies. This is recommended because it guarantees that all your `Caf.js` dependencies have been tested together. Ditto with your modules under `caf/playground`, i.e., they are part of the workspace and do not need to be published during development.

## Getting Started

Install `node` >=10 and `yarn` >=1.3.2. Our development is mostly on Linux. Note that `npm` does not understand Yarn workspaces, you need to use `yarn`.

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
and now let's build and run locally a simple app:
```
    cd apps/caf_helloworld; cafjs build; cafjs run helloworld
```
The first call to `cafjs run` may take a few minutes because it downloads the core Docker images. If your connection is slow you may see timeout exceptions, which can be ignored because it continues with the download.

The app server URL is http://root-launcher.vcap.me (DNS always resolves `*.vcap.me` to `127.0.0.1`, i.e., the local loop). With your browser, login with user `foo` and password `pleasechange`, and then click the `+` icon to add a `helloworld` CA. A CA (Cloud Assistant) is a cloud proxy instance for your app. Fill the form as follows:

* Application publisher: `root`
* Application name: `helloworld`
* CA name: anything containing ASCII characters and numbers.

and a `counter` example should appear. Use the `+` again to create other CAs, and then select the menu on the top left to switch between them.

To stop it, a single `Control-C` will initiate a gentle container shutdown but, for the impatient, a second `Control-C` will brute force a clean-up.

In both cases we should be able to restart without losing the CA's state. This state is checkpointed using a Redis container that mounts a host volume (log file in `/tmp/redis/appendonly.aof`, host port 6380). To start from scratch, delete the log file in the host.

With the `cafjs` command we can also create apps from templates, simulate devices, build container images to publish in our cloud service, i.e., https://root-launcher.cafjs.com, or reset after a hang. See {@link external:caf_dcinabox} (https://cafjs.github.io/api/caf_dcinabox) for details.
