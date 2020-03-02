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
#      } && tsh::addFunc my_function_test
#      # ...
#
# Then test all the functions:
#
#      tsh__test_funcs
#
########################################
tsh__DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
tsh__TEST_DIR="${tsh__DIR}/.testslh"
tsh__TEST_FILE_PREXIX="test__"

tsh::listTests() {
  ls -d ${tsh__DIR}/tests/*
}

## Array of functions to test
tsh::resetFuncs() {
  tsh__funcs=()
} && tsh::resetFuncs

tsh::addFunc() {
  #
  # Adds a function name to execute for the testing framework.
  #
  [ -z "${1:+x}" ] || tsh__funcs+=("$1")
}

tsh::testModules() {
  local msg=""
  msg+="v OK: Successful test\n"
  msg+="x KO: Failed Test\n"
  msg+="Stats: test-index:expected-status:returned-status\n"
  printf "$msg"
 
  for mod in $(tsh::listTests); do
    tsh::resetFuncs
    source "$mod"
    printf "\n[$(basename $mod)]\n"
    tsh::testFuncs 
  done
}

tsh::testFuncs() {
  #
  # Launches all the registered testing functions.
  #
  set +u
  mkdir -p $tsh__TEST_DIR
  local ret=0 
  for func in "${tsh__funcs[@]}"; do
    local funcStatus="" msgStatus=() msg=""
    $func
    funcStatus=$?
    if [ $funcStatus -eq 0 ]; then
      msg+=" v OK"
    else
      msg+=" x KO"
      ret=1
    fi
    
    msg+=" - function '$func'"
    msg+=" - stats ${msgStatus[@]}"
    msg+=" - returned $funcStatus"
    printf "$msg\n" >&2 
  done
  #rm -rf $tsh__TEST_DIR
  return $ret
}

tsh::expectStatus() {
  #
  # Sets the variable msgStatus that is used as extra information in 
  # tsh::testFuncs(). The parameter to give is a string of the form 
  #   NoCommand:ExectedStatus. 
  # If I am exectuting the third command and I expect an exit status
  # of 7, the parameter 3:7 should be passed. Example:
  #
  #   test__myfunction()
  #     command1
  #     command2
  #     command3; tsh::expectStatus 3:7 
  #     return ret
  #   } && tsh::addFunc test__myfunction
  #
  local status=$? task expected
  IFS=':' read -r task expected <<< "$1"
  msgStatus+=("$task:$expected:$status")
}
