#!/bin/bash

function get_last_version {
  echo "resolving the last version..."
  LAST_VERSION=`curl https://api.fastly.com/service/${SERVICE_ID} -H "Fastly-Key: ${TOKEN}" | jq '.versions | .[] | .number' | tail -n 1`
  echo "the last version is ${LAST_VERSION}"
}

function clone_new_version {
  echo "cloning it..."
  THIS_VERSION=`curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/${LAST_VERSION}/clone -H "Fastly-Key: ${TOKEN}" | | jq '.number'`
  echo "created version ${THIS_VERSION}"
}

function build_vcl {
  echo "building vcl..."
  ./build.sh
  VCL_HASH=$(cat output.vcl | md5)
  VCL_FILE=$(printf "${VCL_HASH}.vcl")

  mkdir -p build
  cp output.vcl build/$VCL_FILE
  echo "built build/${VCL_FILE}"
  rm output.vcl
}

function upload_vcl {
  curl -X POST https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/vcl -H "Fastly-Key: ${TOKEN}" -H 'Content-Type: multipart/form-data' --data "name=${VCL_HASH}&main=true" --data-urlencode "content@build/${VCL_FILE}" | jq
}

function activate_vcl {
  curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/${THIS_VERSION}/activate -H "Fastly-Key: ${TOKEN}" | jq
}

function run_tests {
  echo "running tests..."
  curl ${DOMAIN}/tests
  echo ""
}


source .env

get_last_version
clone_new_version
build_vcl
upload_vcl
activate_vcl
run_tests
