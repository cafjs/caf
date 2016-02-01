# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app and IoT devices.

See http://www.cafjs.com 

## CAF top level project
[![Build Status](http://ci.cafjs.com/api/badges/cafjs/caf/status.svg)](http://ci.cafjs.com/cafjs/caf)

This repository provides a consistent snapshot of all the other CAF sub-projects. They are tested together to create an implicit CAF release. CAF tools help apps to stick to a particular release by using `npm link` and `npm shrinkwrap` under the hood.

Clone this repository and update submodules recursively, i.e.:

      cd caf; git submodule update --init 

Satisfy node dependencies and create symbolic links to CAF libs with:

    ./tools/setupLinks.sh

Create a Docker container with the helloworld app (needs Linux with Docker >=1.9):

    ./tools/caf_dcinabox/mkContainer.js --src ./apps/caf_helloworld --container registry.cafjs.com:32000/root-helloworld

Start an application locally:

    ./tools/caf_dcinabox/dcinabox.js --appLocalName helloworld --appImage registry.cafjs.com:32000/root-helloworld

and that starts a local web launcher at http://root-launcher.vcap.me . Login with user 'foo' and  password:'pleasechange' and create CA instances of the app root\_helloworld (i.e., appPublisher\_appLocalName).

Modify your app `caf_helloworld` in subdir `apps`, and then rerun `mkContainer.js`. Refresh it without losing state by restarting `dcinabox` (stop it with Control-C, and wait a few seconds to clean up all the containers).

Finally, create an account in https://root-launcher.cafjs.com , tag the container to  `registry.cafjs.com:32000/your\_user\_name-helloworld`, push it with docker,  and use the `turtles` web app to make it live. Then, any other `cafjs.com` user can create CA instances of your app. Remember, `cafjs.com` is currently a test web platform with very limited resources, not a production system. 

