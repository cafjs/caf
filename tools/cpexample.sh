#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#define CAF_DEVELOPER to use locally installed modules
CAF_DIR=${CAF_DIR:-$HOME/.caf}
CAF_CONFIG=${CAF_CONFIG:-'caf.conf'}

CAF_SUFFIX=${CAF_SUFFIX:-''}

# relative to DIR
CAF_EXAMPLES_DIR=${CAF_EXAMPLES_DIR:-../caf_examples}
CAF_ACCOUNTS=${CAF_ACCOUNTS:-'https://accounts.cafjs.com/app.html'}

# Read configuration variable file if it is present to override above
CAF_FILE=${CAF_DIR}/${CAF_CONFIG}
[ -r ${CAF_FILE} ] && . ${CAF_FILE}

pushd ${DIR}
pushd ${CAF_EXAMPLES_DIR}

app=$1
app=${app%/}
[[ $app ]] || { echo "Invalid input." >&2; exit 1; }

pushd ${app}

#make sure that package.json includes modules imported in framework.json 
${DIR}/checkDeps.js;

if [ $? -ne 0 ] 
then 
    echo "Invalid deps in package.json" >&2; exit 1;
fi
popd #{app}

rm -fr /tmp/${app}-withlinks
rm -fr /tmp/${app}
mkdir /tmp/${app}-withlinks
cp -r ${app}/* /tmp/${app}-withlinks
rm -f /tmp/${app}.tar
pushd /tmp/${app}-withlinks

if [ -z $CAF_DEVELOPER ]
then
    npm install --link
else
#explicitly link to local modules first (developer mode) 
    export deps=`${DIR}/findDeps.js`;
    for dep in $deps; do npm link $dep ; done
    rm -f npm-shrinkwrap.json
    npm install --link
    npm shrinkwrap
    if [ $? -ne 0 ] 
    then 
        echo "Cannot shrinkwrap" >&2; exit 1;
    fi
    cp npm-shrinkwrap.json ${DIR}/${CAF_EXAMPLES_DIR}/${app}
fi

#patch accounts service
pushd lib
sed -i s,https://accounts.cafjs.com/app.html,${CAF_ACCOUNTS},g framework.json
popd #lib


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
rm -fr ${app}${CAF_SUFFIX}
mv package ${app}${CAF_SUFFIX}
tar -xzf  ${app}.tgz 

pushd  package
zip -r ../${app}.zip .
popd #"../"

popd #"../"

popd #/tmp/${app}-withlinks

popd #${CAF_EXAMPLES_DIR}/
popd #${DIR}
