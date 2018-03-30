#!/usr/bin/env bash
#
# This library is intended to help writing and debugging testing
# functions.
# When a testing function is written, it shall be added to the list of
# functions to test as following in your script:
#
#      source testsh.lib
#      function my_function_test() {
#        dothis;
#        dothat;
#        true || return 1
#      } && tsh__add_func my_function_test
#      # ...
#
# Then test all the functions:
#
#      tsh__test_funcs
#
########################################
set -euf -o pipefail

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
  local _status=0
  for _test in "${tsh__funcs[@]}"; do
    printf "  function '$_test'" >&2 
    $_test \
     && printf "\tv OK\n" >&2 \
     || {
         printf "\tx KO ($?)\n" >&2 \
          && _status=1
        }   
  done
  return $_status
}
