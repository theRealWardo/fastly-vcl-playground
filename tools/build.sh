#!/bin/bash

CHECK_TEMPALTE=templates/testing_check.vcl


function compile_functions {
  printf "compiling functions... "
  function_files=$(find functions | grep "\.vcl$")
  output_tmp_file=$(mktemp /tmp/fastly-vcl.XXXXXX)
  for function_file in $function_files; do
    echo "# -- IMPORT ${function_file}" >> $output_tmp_file
    cat ${function_file} >> $output_tmp_file
    echo "# -- END ${function_file}" >> $output_tmp_file
    printf "\n\n" >> $output_tmp_file
  done

  FUNCTIONS=$(cat $output_tmp_file)
  rm $output_tmp_file
  printf "OK\n"
}

function compile_tests {
  printf "compiling tests... "
  test_files=$(find tests | grep "\.vcl$")
  output_tmp_file=$(mktemp /tmp/fastly-vcl.XXXXXX)
  tests_names_file=$(mktemp /tmp/fastly-vcl.XXXXXX)

  for test_file in $test_files; do
    test_name=$(echo ${test_file} | sed 's/[^[:alnum:]]/_/g' | sed 's/tests_//g')
    echo $test_name >> $tests_names_file

    echo "# -- IMPORT ${test_file}" >> $output_tmp_file
    cat $test_file | sed "s/sub assert /sub ${test_name}_assert /g" | sed "s/sub test /sub ${test_name}_test /g" | sed "s/call check;/call ${test_name}_check;/g" >> $output_tmp_file
    echo "# -- END ${test_file}" >> $output_tmp_file
    printf "\n\n" >> $output_tmp_file
    echo "# -- GEN CHECK ${test_file}" >> $output_tmp_file
    escaped_file_name=$(echo "${test_file}"| sed 's/\//\\\//g')
    cat $CHECK_TEMPALTE | sed "s/__FILE__/${escaped_file_name}/g" |sed "s/sub check /sub ${test_name}_check /g" | sed "s/call assert;/call ${test_name}_assert;/g">> $output_tmp_file
    echo "# -- END CHECK ${test_file}" >> $output_tmp_file
  done

  TESTS=$(cat $output_tmp_file)
  rm $output_tmp_file

  TEST_NAMES=$(cat $tests_names_file)
  rm $tests_names_file
  printf "OK\n"
}

function build_output {
  printf "building output... "
  output_tmp_file=$(mktemp /tmp/fastly-vcl.XXXXXX)
  echo "${FUNCTIONS}" >> $output_tmp_file
  echo "${TESTS}" >> $output_tmp_file

  # Call all of the tests in a "tests" function.
  echo "# -- GEN -- TESTS" >> $output_tmp_file
  echo "sub tests {" >> $output_tmp_file
  for t in $TEST_NAMES; do
    echo "  call ${t}_test;" >> $output_tmp_file
  done
  echo "}" >> $output_tmp_file
  echo "# -- END -- TESTS" >> $output_tmp_file
  printf "\n\n" >> $output_tmp_file

  # Generate the X-VCL-MD5 header function.
  VCL_MD5=$2
  if [[ -z $VCL_MD5 ]]; then
    VCL_MD5="dev"
  fi
  printf "using MD5 ${VCL_MD5}... "
  echo "# -- GEN -- x_vcl_md5" >> $output_tmp_file
  echo "sub x_vcl_md5 {" >> $output_tmp_file
  echo "  set resp.http.X-VCL-MD5 = \"${VCL_MD5}\";" >> $output_tmp_file
  echo "}" >> $output_tmp_file
  echo "# -- END -- TESTS" >> $output_tmp_file
  printf "\n\n" >> $output_tmp_file

  printf "using template ${1}... "
  cat $1 >> $output_tmp_file

  mv $output_tmp_file output.vcl
  printf "OK\n"
}


if [[ -z $1 ]]
then
  echo "usage: ./tools/build.sh TEMPLATE (MD5_HASH)"
  exit 1
fi

compile_tests
compile_functions
build_output $1 $2
