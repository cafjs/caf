#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
pushd ../caf_core/
npm link
popd
export topdirs="../caf_lib ../caf_extra"
for topdir in $topdirs; do 
    pushd "$topdir"
    export libdirs=`ls -d */`
    for lib in $libdirs; do 
        pushd "$lib"; 
        export deps=`../../tools/findDeps.js`;
        for dep in $deps ; do
            npm link $dep ;
        done ;
        npm link
        popd ; 
    done ;
    popd
done
popd
