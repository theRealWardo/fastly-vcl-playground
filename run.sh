#!/bin/bash

source .env


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
  printf "building vcl from template ${1}... "

  ./tools/build.sh $1
  VCL_HASH=$(cat output.vcl | md5)
  # rebuild it with the hash baked in now.
  ./tools/build.sh $1 $VCL_HASH

  mkdir -p build
  VCL_FILE=$(printf "${VCL_HASH}.vcl")
  cp output.vcl build/$VCL_FILE
  printf "built build/${VCL_FILE}\n"
  rm output.vcl
}

function reset_custom_vcl {
  echo "resetting custom VCL for version ${THIS_VERSION}..."
  VCLS=$(curl https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/vcl -H "Fastly-Key: ${TOKEN}" 2>/dev/null | jq -r '.[] | .name')
  for vcl in $VCLS; do
    printf "deleting ${vcl}... "
    output=$(curl -X DELETE https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/vcl/${vcl} -H "Fastly-Key: ${TOKEN}" 2>/dev/null)
    success=$(echo "${output}" | jq -r '.status')
    if [[ $success == "ok" ]]
    then
      printf "OK\n"
    else
      printf "ERROR\n\n"
      echo "${output}"
      exit 1
    fi
  done
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
  result=$(curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/activate -H "Fastly-Key: ${TOKEN}" 2>/dev/null)
  VERSION=$(echo "${result}" | jq '.number')
  if [[ $VERSION == $THIS_VERSION ]]
  then
    printf "OK\n"
  else
    printf "ERROR\n\n"
    echo "$result"
    exit 1
  fi
}

function test_hash {
  printf "testing hash ${VCL_HASH}..."
  HASH=""
  CURRENT=""
  while [[ $HASH != $VCL_HASH ]]
  do
    sleep 1
    export TEST_RESULT=$(curl ${DOMAIN}/tests -vvv 2>&1)
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
  printf "\n\n\n"
  echo "#########################"
  echo "         RESULTS"
  echo "#########################"
  printf "\n\n"
  echo "${TEST_RESULT}"
}

function rebuild_backends {
  ./tools/reset_backends.sh ${THIS_VERSION}
  echo "loading backends from $1..."
  backends=$(./tools/backends.sh $1)
  for backend in $backends; do
    printf "adding backend... "
    NAME=$(curl -X POST https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/backend -H "Fastly-Key: ${TOKEN}" -H "Content-Type: application/x-www-form-urlencoded" -d "${backend}" 2>/dev/null | jq -r '.name')
    if [[ $NAME == "null" ]]
    then
      printf "error adding backend: ${backend}\n"
      exit 1
    fi
    printf "${NAME} added.\n"
  done
}


if [[ -z $1 || -z $2 ]]
then
  echo "usage: ./run.sh TEMPLATE BACKENDS"
  exit 1
fi


build_vcl $1
get_last_version
clone_new_version
reset_custom_vcl
upload_vcl
rebuild_backends $2
activate_vcl

test_hash ${VCL_HASH}
