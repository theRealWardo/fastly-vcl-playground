#!/bin/bash

function compile_functions {
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
}

function compile_tests {
  test_files=$(find tests | grep "\.vcl$")
  output_tmp_file=$(mktemp /tmp/fastly-vcl.XXXXXX)
  tests_names_file=$(mktemp /tmp/fastly-vcl.XXXXXX)

  for test_file in $test_files; do
    test_name=$(echo ${test_file} | sed 's/[^[:alnum:]]/_/g' | sed 's/tests_//g')
    echo $test_name >> $tests_names_file

    echo "# -- IMPORT ${test_file}" >> $output_tmp_file
    cat $test_file | sed "s/sub test /sub ${test_name}_test /g" >> $output_tmp_file
    echo "# -- END ${test_file}" >> $output_tmp_file
    printf "\n\n" >> $output_tmp_file
  done

  TESTS=$(cat $output_tmp_file)
  rm $output_tmp_file

  TEST_NAMES=$(cat $tests_names_file)
  rm $tests_names_file
}

function build_output {
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

  cat main.vcl >> $output_tmp_file

  mv $output_tmp_file output.vcl
}


compile_tests
compile_functions
build_output
