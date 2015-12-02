#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
export topdirs="../main ../extra"

for topdir in $topdirs; do 
    pushd "$topdir"
    export libdirs=`ls -d */`
    for lib in $libdirs; do 
	if [ -d "$lib" ]
	then
            pushd "$lib";
	    npm install  --link
	    npm link
            popd ;
	fi
    done ;
    popd
done
popd
