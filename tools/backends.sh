#!/bin/bash

function parse_backends {
  data=$(cat $1)
  output_tmp_file=$(mktemp /tmp/fastly-vcl.XXXXXX)
  backend=""

  for l in $data; do
    if [[ $l == "BACKEND" ]]
    then
      if [[ -n $backend ]]
      then
        echo "${backend}" >> $output_tmp_file
      fi
      backend=""
    elif [[ $backend != "" ]]
    then
      backend=$(printf "${backend}&${l}")
    else
      backend=$(printf "${l}")
    fi
  done

  echo "${backend}" >> $output_tmp_file

  BACKENDS=$(cat $output_tmp_file)
  echo "${BACKENDS}"
  rm $output_tmp_file
}


parse_backends $1
