#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}
topdirs="../apps"
mkOne=${DIR}/caf_dcinabox/bin/caf.js
REGISTRY_PREFIX=${REGISTRY_PREFIX:-'gcr.io/cafjs-k8'}
REGISTRY_USER=${REGISTRY_USER:-'root'}
EXTRA="caf_gadget_daemon caf_netproxy"
MAX_JOBS=${MAX_JOBS:-'8'}

# see https://stackoverflow.com/questions/1537956/bash-limit-the-number-of-concurrent-jobs
job_limit () {
    if (( $# == 1 )) && [[ $1 =~ ^[1-9][0-9]*$ ]]
    then

        joblist=($(jobs -rp))
        while (( ${#joblist[*]} >= $1 ))
        do
            command='wait '${joblist[0]}
            for job in ${joblist[@]:1}
            do
                command+=' || wait '$job
            done
            eval $command
            joblist=($(jobs -rp))
        done
   fi
}

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
            job_limit $MAX_JOBS
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
        job_limit $MAX_JOBS
    fi
done ;
wait
popd #extra

popd

docker tag  gcr.io/cafjs-k8/root-gadget_daemon gcr.io/cafjs-k8/root-rpidaemon
