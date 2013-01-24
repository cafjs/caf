#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $DIR
pushd ${DIR}
pushd ../caf_examples/

app=$1
app=${app%/}
[[ $app ]] || { echo "Invalid input." >&2; exit 1; }

pushd ${app}

${DIR}/checkDeps.js;

if [ $? -ne 0 ] 
then 
    echo "Invalid deps in package.json" >&2; exit 1;
fi
popd

rm -fr /tmp/${app}-withlinks
rm -fr /tmp/${app}
mkdir /tmp/${app}-withlinks
cp -r ${app}/* /tmp/${app}-withlinks
rm -f /tmp/${app}.tar
pushd /tmp/${app}-withlinks

export deps=`${DIR}/findDeps.js`;
for dep in $deps ; do
    npm link $dep ;
done ;
rm -f npm-shrinkwrap.json
npm install
npm shrinkwrap
if [ $? -ne 0 ] 
then 
    echo "Cannot shrinkwrap" >&2; exit 1;
fi

cp npm-shrinkwrap.json ${DIR}/../caf_examples/${app}

pushd "../"
cp -rL  ${app}-withlinks ${app}
pushd ${app}
#clean up redundant dependencies
${DIR}/renameRedundant.js
if [ $? -ne 0 ] 
then 
    echo "Cannot eliminate redundant deps" >&2; exit 1;
fi
find . -name "*-delete-12345" | xargs rm -fr 
popd #${app}
rm -fr package
mv ${app} package
tar --exclude=test  --exclude=samples --exclude=tools --exclude=.git -c -h -z -f ${app}.tgz package
mv package ${app}
tar -xzf  ${app}.tgz 

popd #"../"

popd #/tmp/${app}-withlinks

popd #../caf_examples/
popd #${DIR}
