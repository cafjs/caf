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
            npm link `${DIR}/caf_dcinabox/bin/findDepsCAF.js`
            npm link `${DIR}/caf_dcinabox/bin/findDevDepsCAF.js`
	    npm install
	    npm link
            popd ;
	fi
    done ;
    popd
done
popd
