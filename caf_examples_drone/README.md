# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app.

See http://www.cafjs.com 

## CAF examples for managing a drone (like AR.Drone 2.0 by Parrot)

** UNDER CONSTRUCTION**

The goal is to enable autonomous drone operation with the help of a CA. To control the drone we no longer talk to it directly, we just give high level instructions to its CA. The drone, instead of creating a local access point and waiting for commands, it connects as a client to a wlan and talks to its CA periodically. In each exchange, the drone uploads sensor information/video and downloads future commands.

Drone commands are grouped into bundles that are atomically executed at pre-determined times. The drone synchronizes its clock using ntp (typically within 100 msec) but timing could also be relative to a previous command. The drone always ensures that it receives all the commands in a bundle before it starts executing any of them. If it is too late to execute the first command in the bundle, the whole bundle gets ignored. Also, once the bundle starts executing it will not stop (unless it receives an emergency command), and it will ignore a future command overlapping in time. Therefore, to maintain responsiveness, bundles typically do not span more than a few seconds.

Atomicity of bundles is required to guarantee safety, i.e., each bundle should terminate with an stable flying state. For example, a first command could involve descending with speed 1 meter/sec. A second command executed after 2 seconds could tell the drone to stop descending. By bundling these two commands we guarantee that regardless of wifi connectivity the drone will not hit the ground (if altitude > 2m). Alternatively, one of the commands could have set the minimum altitude, and then we could have continued the descent without stopping across multiple bundles.

