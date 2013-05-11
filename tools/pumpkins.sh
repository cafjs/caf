#!/bin/bash
#comment this line for vanilla cloud foundry
STACKATO=true
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CAFDIR=$HOME/.caf
pushd ${DIR}

export apps='website helloworld hellosharing mail moody pull mutant justonce turtles rps tutorial1a tutorial1b tutorial1c tutorial1d tutorial1e'

# Do this manually when caf_enyo changes
#pushd ../caf_core/public/enyo/
#./tools/deploy.sh
#popd

pushd ../caf_examples/turtles/lib
CFPASS=`cat ${CAFDIR}/cfpassword`
sed -i s/cfpassword/${CFPASS}/g framework.json
popd


for app in $apps; do ./cpexample.sh "$app" ; done

pushd ../caf_examples/turtles/lib
sed -i s/${CFPASS}/cfpassword/g framework.json
popd

if test -z $STACKATO ; then
    for app in $apps; do ./deletevmc.sh "$app" ; done    
    for app in $apps; do ./pushvmc.sh "$app" ; done
    ./mapvmc.sh website http://www.cafjs.com
else 
    for app in $apps; do ./deletestackato.sh "$app" ; done    
    for app in $apps; do ./pushstackato.sh "$app" ; done
    ./mapstackato.sh website http://www.cafjs.com
fi
popd
