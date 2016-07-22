#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR
pushd ${DIR}
export docs='framework gettingstarted standalone codingconventions'

pushd ../caf_examples/website/public

for doc in $docs; do multimarkdown ../../../docs/"$doc".md -o "$doc".inc ; done  
popd
popd
