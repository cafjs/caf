# CAF (Cloud Assistant Framework)

Co-design permanent, active, stateful, reliable cloud proxies with your web app.

See http://www.cafjs.com 

## CAF examples for managing a drone (like AR.Drone 2.0 by Parrot)

** UNDER CONSTRUCTION**

The goal is to enable autonomous drone operation with the help of a CA. To control the drone we no longer talk to it directly, we just give high level instructions to its CA. The drone, instead of creating a local access point and waiting for commands, it connects as a client to a wlan and talks to its CA periodically. In each exchange, the drone uploads sensor information/video and downloads future commands.

Drone commands are grouped into bundles that are atomically executed at pre-determined times. The drone synchronizes its clock using ntp (typically within 100 msec) but timing could also be relative to a previous command. The drone always ensures that it receives all the commands in a bundle before it starts executing any of them. If it is too late to execute the first command in the bundle, the whole bundle gets ignored. If a new bundle starts executing before the previous bundle finished, the commands that were not yet scheduled will be ignored. 

We recommend to end a bundle with an emergency recovery command(s) that will execute after a safety time threshold. Bundles are pipelined, and in normal operation a new bundle will start executing before that recovery action takes place, and therefore, this action will be ignored. However, if we lose connectivity to the drone, there are no more scheduled actions, and the drone will be placed in a safe state. Clearly, caching a complete bundle in the drone before executing any of its commands is required to guarantee safety.

Safety thresholds are chosen based on a logical bounding box that the drone should not cross. Each bundle shifts the position of that box to accomodate future movements of the drone.  The time to cross this box is dependent on the drone speed after executing the last command, and we use a simple linear model to conservatively estimate that time.

