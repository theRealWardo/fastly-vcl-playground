#!/bin/bash

function get_last_version {
  printf "resolving the last version... "
  LAST_VERSION=`curl https://api.fastly.com/service/${SERVICE_ID} -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq '.versions | .[] | .number' | tail -n 1`
  printf "the last version is ${LAST_VERSION}\n"
}

function clone_new_version {
  printf "cloning it... "
  THIS_VERSION=`curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/${LAST_VERSION}/clone -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq '.number'`
  printf "created version ${THIS_VERSION}\n"
}

function build_vcl {
  printf "building vcl... "

  ./build.sh
  VCL_HASH=$(cat output.vcl | md5)
  # rebuild it with the hash baked in now.
  ./build.sh $VCL_HASH

  mkdir -p build
  VCL_FILE=$(printf "${VCL_HASH}.vcl")
  cp output.vcl build/$VCL_FILE
  printf "built build/${VCL_FILE}\n"
  rm output.vcl
}

function upload_vcl {
  printf "uploading ${VCL_HASH} for version ${THIS_VERSION}... "
  NAME=$(curl -X POST https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/vcl -H "Fastly-Key: ${TOKEN}" -H 'Content-Type: multipart/form-data' --data "name=${VCL_HASH}&main=true" --data-urlencode "content@build/${VCL_FILE}" 2>/dev/null | jq '.name')
  if [[ $NAME == "null" ]]
  then
    printf "error while uploading VCL. maybe it is already uploaded?\n"
    exit 1
  else
    printf "OK\n"
  fi
}

function activate_vcl {
  printf "activating version ${THIS_VERSION}... "
  VERSION=$(curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/activate -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq '.number')
  printf "OK\n"
}

function test_hash {
  printf "testing hash ${VCL_HASH}..."
  HASH=""
  CURRENT=""
  while [[ $HASH != $VCL_HASH ]]
  do
    sleep 1
    export TEST_RESULT=$(curl http://chunk-transfer-demo.cdn.mux.io/tests -vvv 2>&1)
    VERSION=$(echo "${TEST_RESULT}" | grep X-VCL-MD5)
    HASH_REGEX="< X-VCL-MD5: ([0-9a-z]+)"
    if [[ $VERSION =~ $HASH_REGEX ]]
    then
      HASH=${BASH_REMATCH[1]}
      if [[ $HASH != $CURRENT && $HASH != $VCL_HASH ]]
      then
        CURRENT=${HASH}
        printf " got ${CURRENT}. waiting."
      else
        printf "."
      fi
    fi
  done
  printf " results:\n"
  echo "${TEST_RESULT}"
}


source .env

get_last_version
clone_new_version
build_vcl
upload_vcl
activate_vcl

test_hash ${VCL_HASH}
