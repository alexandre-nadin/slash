#!/usr/bin/env bash
#
# This library is intended to help writing and debugging testing
# functions.
# When a testing function is written, it shall be added to the list of
# functions to test as following in your script:
#
#      source testslh.sh
#      function my_function_test() {
#        dothis;
#        dothat;
#        true                                                   || return 1
#      } && tsh__add_func my_function_test
#      # ...
#
# Then test all the functions:
#
#      tsh__test_funcs
#
########################################
source source.sh
source::unique decorator.sh

tsh__TEST_DIR="./.testslh"
tsh__TEST_FILE_PREXIX="test__"

## Array of functions to test
tsh__funcs=()

tsh__add_func() {
  #
  # Adds a function name to execute for the testing framework.
  #
  [ -z "${1:+x}" ] \
   || tsh__funcs+=("$1")
}

tsh__has_tests() {
  [ ${#tsh__funcs[@]} -gt 0 ]
}

tsh__test_funcs() {
  #
  # Launches all the registered testing functions.
  #
  set +u
  mkdir -p $tsh__TEST_DIR
  local _status=0
  for _test in "${tsh__funcs[@]}"; do
    $_test \
     && printf " v OK - function '$_test'\n" >&2 \
     || {
         printf " x KO - function '$_test' ($?)\n" >&2 \
          && _status=1
        }   
  done
  rm -rf $tsh__TEST_DIR
  return $_status
}
