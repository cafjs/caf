#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
topdirs="../apps"
REGISTRY_PREFIX=${REGISTRY_PREFIX:-'registry.cafjs.com:32000'}
REGISTRY_USER=${REGISTRY_USER:-'root'}

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
            docker push "${REGISTRY_PREFIX}/${REGISTRY_USER}-${name}"
	fi
    done ;
    popd
done
popd
