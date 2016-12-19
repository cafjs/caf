# CAF.js (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app and IoT devices.

See http://www.cafjs.com

## CAF
[![Build Status](http://ci.cafjs.com/api/badges/cafjs/caf/status.svg)](http://ci.cafjs.com/cafjs/caf)

This repository provides a consistent snapshot of all the other CAF sub-projects. They are tested together to create an implicit CAF release. CAF tools help apps to stick to modules of a particular release by using `npm link` and `npm shrinkwrap` under the hood.

### Getting Started

Clone this repository (`git clone https://github.com/cafjs/caf.git`) inside your `$HOME` directory, and update submodules recursively:

      cd caf; git submodule update --init

Satisfy node dependencies and create symbolic links to CAF libs with:

    ./tools/setupLinks.sh

Install the tools:

    cd tools/caf_dcinabox; npm install -g .

And now let's build and run locally a simple app:

    cd apps/caf_helloworld; cafjs build; cafjs run helloworld

the first time we call `cafjs run` it takes a few minutes, because it downloads the core Docker images. Ignore timeout exceptions during that time.

The app server with URL http://root-launcher.vcap.me (DNS always resolves `*.vcap.me` to `127.0.0.1`, i.e., the local loop) should be up. With your browser, login with user `foo` and password `pleasechange`, and then click the `+` icon to add a `helloworld` CA. Fill the form as follows:

* Application publisher: `root`
* Application name: `helloworld`
* CA name: anything containing ASCII characters and numbers.

and a `counter` example should appear. Use the `+` again to create other CAs, and then select the menu on the top right to switch between them.

To stop it, a single `Control-C` will initiate a gentle container shutdown but, for the impatient, a second `Control-C` will brute force a clean-up.

In both cases we should be able to restart without losing the CA's state. This state is checkpointed in a Redis container (host port 6380, log file in `/tmp/redis/appendonly.aof`). To start from scratch, delete the log file in the host.

Using the `cafjs` command we can also simulate devices, build container images to publish in our cloud service, i.e., https://root-launcher.cafjs.com, or reset after a hang. See {@link external:caf_dcinabox} (https://cafjs.github.io/api/caf_dcinabox) for details.
