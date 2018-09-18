#!/bin/bash

source .env
source tools/urlencode.sh


function list_backends {
  printf "loading backends... "
  BACKENDS=$(curl https://api.fastly.com/service/${SERVICE_ID}/version/${VERSION}/backend -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq -r '.[] | .name')
  printf "OK\n"
}

function delete_backends {
  IFS=$'\n'
  for backend in $BACKENDS; do
    encoded_backend=$(urlencode "${backend}")
    printf "deleting version $VERSION backend: ${backend}... "
    success=$(curl -X DELETE https://api.fastly.com/service/${SERVICE_ID}/version/${VERSION}/backend/${encoded_backend} -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq -r '.status')
    if [[ $success == "ok" ]]
    then
      printf "OK\n"
    else
      printf "ERROR\n"
      exit 1
    fi
  done
}


VERSION=$1
list_backends
delete_backends
