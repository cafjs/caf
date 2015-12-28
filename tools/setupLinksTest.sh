#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
export topdirs="../main ../extra ../tools"

for topdir in $topdirs; do 
    pushd "$topdir"
    export libdirs=`ls -d */`
    for lib in $libdirs; do 
	if [ -d "$lib" ]
	then
            pushd "$lib";
            rm -fr node_modules/*
	    npm install --link
	    npm link
            popd ;
	fi
    done ;
    popd
done
popd
