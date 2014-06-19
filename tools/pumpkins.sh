#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CAF_DIR=${CAF_DIR:-$HOME/.caf}
CAF_CONFIG=${CAF_CONFIG:-'caf.conf'}


# define STACKATO to use stackato cli
#STACKATO=true

CAF_USER=${CAF_USER:-'foo@bar.com'}
CAF_PASS=${CAF_PASS:-'pleasechange'}
CAF_TARGET=${CAF_TARGET:-'https://api.cafjs.com'}
CAF_SUFFIX=${CAF_SUFFIX:-''}

CAF_APPS=${CAF_APPS:-'website helloworld hellosharing hellodrone mail moody pull mutant justonce turtles rps tutorial1a tutorial1b tutorial1c tutorial1d tutorial1e'}
CAF_WEBSITE=${CAF_WEBSITE:-'www.cafjs.com'}  


# Read configuration variable file if it is present to override above
CAF_FILE=${CAF_DIR}/${CAF_CONFIG}
[ -r ${CAF_FILE} ] && . ${CAF_FILE}

#no extra mapping if CAF_MAP == CAF_TARGET
# otherwise we replace 'api' by app name in url
CAF_MAP=${CAF_MAP:-${CAF_TARGET}}

pushd ${DIR}



# Do this manually when caf_enyo changes
#pushd ../caf_core/public/enyo/
#./tools/deploy.sh
#popd

pushd ../caf_examples/turtles/lib
sed -i s/cfpassword/${CAF_PASS}/g framework.json
sed -i s/foo@bar.com/${CAF_USER}/g framework.json
sed -i s,https://api.cafjs.com,${CAF_TARGET},g framework.json
if [ $CAF_TARGET != $CAF_MAP ] 
then
    sed -i s,null,\"${CAF_MAP}\",g framework.json
fi
popd

for app in $CAF_APPS; do ./cpexample.sh "$app" ; done

#undo damage...
pushd ../caf_examples/turtles/lib
sed -i s/${CAF_PASS}/cfpassword/g framework.json
sed -i s/${CAF_USER}/foo@bar.com/g framework.json
sed -i s,${CAF_TARGET},https://api.cafjs.com,g framework.json
if [ ${CAF_TARGET} != ${CAF_MAP} ] 
then
    sed -i s,\"${CAF_MAP}\",null,g framework.json
fi
popd


if [ -z $STACKATO ] 
then
    for app in $CAF_APPS; do ./deletevmc.sh "${app}${CAF_SUFFIX}" ; done    
    for app in $CAF_APPS; do ./pushvmc.sh "${app}${CAF_SUFFIX}" ; done
    if [ $CAF_TARGET != $CAF_MAP ] 
    then
        for app in $CAF_APPS; do ./mapvmc.sh "${app}${CAF_SUFFIX}" ${CAF_MAP/api/$app} ; done 
    fi
    ./mapvmc.sh website ${CAF_WEBSITE}
else 
    for app in $CAF_APPS; do ./deletestackato.sh "${app}${CAF_SUFFIX}" ; done    
    for app in $CAF_APPS; do ./pushstackato.sh "${app}${CAF_SUFFIX}" ; done
    if [ $CAF_TARGET != $CAF_MAP ] 
    then
        for app in $CAF_APPS; do ./mapstackato.sh "${app}${CAF_SUFFIX}" ${CAF_MAP/api/$app} ; done 
    fi
    ./mapstackato.sh website ${CAF_WEBSITE}
fi
popd
