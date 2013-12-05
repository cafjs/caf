#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CAF_DIR=${CAF_DIR:-$HOME/.caf}
CAF_CONFIG=${CAF_CONFIG:-'caf.conf'}


# define STACKATO to use stackato cli
#STACKATO=true

CAF_TARGET=${CAF_TARGET:-'http://api.cafjs.com'}
CAF_SUFFIX=${CAF_SUFFIX:-''}

CAF_PRIV_APPS=${CAF_PRIV_APPS:-'accounts'}

# Read configuration variable file if it is present to override above
CAF_FILE=${CAF_DIR}/${CAF_CONFIG}
[ -r ${CAF_FILE} ] && . ${CAF_FILE}

#no extra mapping if CAF_MAP == CAF_TARGET
# otherwise we replace 'api' by app name in url
CAF_MAP=${CAF_MAP:-${CAF_TARGET}}

pushd ${DIR}

pushd ../caf_core/public/enyo/
./tools/deploy.sh
popd

pushd ../caf_examples/accounts/lib
cp $CAF_DIR/rsa_priv.pem .
popd


for app in $CAF_PRIV_APPS; do ./cpexample.sh "$app" ; done

#undo damage
pushd ../caf_examples/accounts/lib
rm -f rsa_priv.pem
popd

if [ -z $STACKATO ] 
then
    for app in $CAF_PRIV_APPS; do ./deletevmc.sh "${app}${CAF_SUFFIX}" ; done    
    for app in $CAF_PRIV_APPS; do ./pushvmc.sh "${app}${CAF_SUFFIX}" ; done
    if [ $CAF_TARGET != $CAF_MAP ] 
    then
        for app in $CAF_PRIV_APPS; do ./mapvmc.sh "${app}${CAF_SUFFIX}" ${CAF_MAP/api/$app} ; done 
    fi
else 
    for app in $CAF_PRIV_APPS; do ./deletestackato.sh "${app}${CAF_SUFFIX}" ; done    
    for app in $CAF_PRIV_APPS; do ./pushstackato.sh "${app}${CAF_SUFFIX}" ; done
    if [ $CAF_TARGET != $CAF_MAP ] 
    then
        for app in $CAF_PRIV_APPS; do ./mapstackato.sh "${app}${CAF_SUFFIX}" ${CAF_MAP/api/$app} ; done 
    fi
fi

#./pumpkins.sh
popd
