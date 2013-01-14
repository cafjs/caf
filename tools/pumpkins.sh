#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CAFDIR=$HOME/.caf
pushd ${DIR}

export apps='website helloworld hellosharing mail moody pull mutant justonce turtles tutorial1a tutorial1b tutorial1c tutorial1d tutorial1e'

pushd ../caf_core/public/enyo/
./tools/deploy.sh
popd

pushd ../caf_examples/turtles/lib
CFPASS=`cat ${CAFDIR}/cfpassword`
sed -i s/cfpassword/${CFPASS}/g framework.json
popd


for app in $apps; do ./cpexample.sh "$app" ; done


for app in $apps; do ./deletevmc.sh "$app" ; done

for app in $apps; do ./pushvmc.sh "$app" ; done

./mapvmc.sh website http://www.cafjs.com

popd
