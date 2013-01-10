#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR
pushd ${DIR}
#export docs='caf_core caf_lib/caf_sharing'
export docs='caf_core'

pushd ../caf_examples/website/public
export ALL_FILES='';
for doc in $docs; do 
#pushd ../../../"$doc"/lib/
ALL_FILES="$ALL_FILES `ls ../../../"$doc"/lib/*.js`" ;
#popd 
 done  
echo $ALL_FILES
jsdoc $ALL_FILES ../../../caf_core/README.md
pushd out
find . -name "*.html" -exec sed -i s/Namespace/Component/g {} \;
popd #out

popd
popd
