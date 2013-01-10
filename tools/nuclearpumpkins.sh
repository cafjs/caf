#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
export apps='accounts'

pushd ../caf_core/public/enyo/
./tools/deploy.sh
popd


for app in $apps; do ./cpexample.sh "$app" ; done


for app in $apps; do ./deletevmc.sh "$app" ; done

for app in $apps; do ./pushvmc.sh "$app" ; done

./pumpkins.sh
popd
