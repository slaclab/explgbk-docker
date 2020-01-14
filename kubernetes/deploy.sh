#!/bin/bash

# set -x

CONFIG_FILE="ENVIRONMENT"
if [ -n "${1}" ]; then
    CONFIG_FILE="${1}"
fi

# import key value pairs
source ./${CONFIG_FILE}

# action
ACTION="${2}"
if [ "${ACTION}" = "--update" ] || [ "${ACTION}" = "--upgrade" ] ; then
  ACTION="replace"
else
  ACTION="apply"
fi 

# stolen from https://starkandwayne.com/blog/bashing-your-yaml/
function gen_template() {
    rm -f final.yaml temp.yaml  
    ( echo "cat <<EOF >final.yaml";
      cat $1;
      echo "EOF";
    ) >temp.yaml
    . temp.yaml
    cat final.yaml
    rm -f final.yaml temp.yaml  
}

# create the namespace for this project
kubectl create namespace ${namespace}

# create the secrets
gen_template "secrets.yaml" | kubectl  -n ${namespace} ${ACTION} -f -

# create the storage pv
gen_template "database-storage.yaml" | kubectl  -n ${namespace} ${ACTION}  -f -
gen_template "cryoem-storage.yaml" | kubectl  -n ${namespace} ${ACTION}  -f -

# create the message bus
# gen_template "message_bus.yaml" | 
gen_template "message_bus.yaml" | kubectl -n ${namespace} ${ACTION} -f -

# create database backend
gen_template "database.yaml" | kubectl  -n ${namespace} ${ACTION}  -f -

# # create the logbook
gen_template "logbook.yaml" | kubectl -n ${namespace} ${ACTION}  -f -
gen_template "auth.yaml" | kubectl -n ${namespace} ${ACTION}  -f -
