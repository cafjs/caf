#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
topdirs="../apps"
mkOne=${DIR}/caf_dcinabox/bin/caf.js
REGISTRY_PREFIX=${REGISTRY_PREFIX:-'gcr.io/cafjs-k8'}
REGISTRY_USER=${REGISTRY_USER:-'root'}
EXTRA="caf_gadget_daemon caf_netproxy"

for topdir in $topdirs; do
    pushd "$topdir"
    export libdirs=`ls -d */`
    for lib in $libdirs; do
	if [ -d "$lib" ]
	then
            prefix="caf_"
            suffix="/"
            name=${lib#$prefix}
            name=${name%$suffix}
            ${mkOne} mkImage "$lib" "${REGISTRY_PREFIX}/${REGISTRY_USER}-${name}" &
	fi
    done ;
    wait
    popd
done

pushd "../extra"
for lib in $EXTRA; do
    if [ -d "$lib" ]
    then
        prefix="caf_"
        suffix="/"
        name=${lib#$prefix}
        name=${name%$suffix}
        ${mkOne} mkImage "$lib" "${REGISTRY_PREFIX}/${REGISTRY_USER}-${name}" &
    fi
done ;
wait
popd #extra

popd
