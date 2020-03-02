#!/usr/bin/env bash
source array.sh

array::duplicateFromToTest() {
  set -u
  local _func="array::duplicateFromTo" _res _ret
  local _arr1 _arr2 _arr3
  ! $_func                                                      || return 1
  ! $_func oen two thre                                         || return 2

  _arr1=(one two " three four" five)
  $_func _arr1 _arr2                                            || return 3
  [ ${#_arr2[@]} -eq ${#_arr1[@]} ]                             || return 4
  ! [ "${_arr2[2]}" == " three four " ]                         || return 5
  [ "${_arr2[2]}" == " three four" ]                            || return 6

  ## We can duplicate empty arrays
  $_func undefined_array _arr2                                  || return 7
  [ "${#_arr2[@]}" -eq 0 ]                                      || return 8
  
  _arr3=(); unset _arr2
  $_func _arr3 _arr2                                            || return 9
  [ "${#_arr2[@]}" -eq 0 ]                                      || return 10
} && tsh::addFunc array::duplicateFromToTest

array::addTest() {
  local _func="array::add" _c
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2

  $_func _c one two                                             || return 3
  [ ${_c[@]:+x} ] \
   && [ ${#_c[@]} -eq 2 ]                                       || return 4
 
  _c=(one thow "three four")
  [ ${#_c[@]} -eq 3 ]                                           || return 5
  $_func _c added1 "added 2" added3
  ! [ "${_c[2]}" = "three fou" ]                                || return 6
  [ "${_c[2]}" = "three four" ]                                 || return 7
  [ "${_c[3]}" = "added1" ]                                     || return 8
  [ "${_c[-1]}" = "added3" ]                                    || return 9
  [ ${#_c[@]} -eq 6 ]                                           || return 10
} && tsh::addFunc array::addTest

array::addUniqueTest() {
  local _func="array::addUnique" _c
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2
  $_func _c "one"                                               || return 3
  [ ${#_c[@]} -eq 1 ]                                           || return 4
  [ "${_c[0]}" == "one" ]                                       || return 5

  $_func _c "one two"                                           || return 6 
  [ ${#_c[@]} -eq 2 ]                                           || return 7

  $_func _c "one "                                              || return 8
  $_func _c " one"                                              || return 9
  [ ${#_c[@]} -eq 4 ]                                           || return 10

  ! $_func _c "one"                                             || return 11
  [ ${#_c[@]} -eq 4 ]                                           || return 12
} && tsh::addFunc array::addUniqueTest

array::dumpTest() {
  local _func="array::dump" _c
  ! $_func                                                      || return 1
  $_func _c &> /dev/null                                        || return 2
  _c=(one thow "three four")
  [ "$($_func _c)" == "$(printf 'one\nthow\nthree four')" ]     || return 3
} && tsh::addFunc array::dumpTest

array::indexesOfTest() {
  local _func="array::indexesOf" _c
  _c=(one thow "three four" one)
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2
  ! $_func _undefined                                           || return 3
  [ "$($_func _c ase | xargs)" = "" ]                           || return 4
  [ "$($_func _c 'three four ' | xargs)" = "" ]                 || return 5
  [ "$($_func _c 'one' | xargs)" = "0 3" ]                      || return 6
} && tsh::addFunc array::indexesOfTest

array::indexesTest() {
  local _func="array::indexes" _c _indexes
  ! $_func                                                      || return 1
  $_func _c                                                     || return 2

  _c=(one thow "three four" one)
  $_func _c &> /dev/null && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 3

  $_func _c | xargs |
   while IFS= read -r _line; do
     [ "$_line" == "0 1 2 3" ]                                  || return 4
   done
} && tsh::addFunc array::indexesTest

array::containsTest() {
  local _func="array::contains" _c
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2 
  ! $_func _c "one"                                             || return 3

  _c=(one thow "three four" one)
  ! $_func _c ase                                               || return 3
  ! $_func _c 'three four '                                     || return 4
  ! $_func _c 'three fo'                                        || return 5
  $_func _c 'one'                                               || return 6
  ! $_func _c ""                                                || return 7
  ! $_func _c " "                                               || return 8
} && tsh::addFunc array::containsTest

test__arrr_popTest() {
  local _func="arrr_pop" _c _res
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2
  ! $_func _c "one"                                             || return 3

  _c=(one two "three four" four five six seven)
  [ ${#_c[@]} -eq 7 ]                                           || return 4
 
  _res="$($_func _c)" && _ret=$? || _ret=$?
  [ "$($_func _c)" == "seven" ]                                 || return 5
  ## We popped it in a subshell. We need to do it in this shell:
  $_func _c &> /dev/null                                        || return 6
  ## (one two "three four" four five six)
  [ ${#_c[@]} -eq 6 ]                                           || return 7

  [ "$($_func _c 2)" == "three four" ]                          || return 8
  [ "$($_func _c -5)" == "two" ]                                || return 9
  [ "$($_func _c -6)" == "one" ]                                || return 10
  ! $_func _c -7                                                || return 11
  [ ${#_c[@]} -eq 6 ]                                           || return 12

  _c=(one)
  ! $_func _c -2                                                || return 13
  [ ${#_c[@]} -eq 1 ]                                           || return 14
  [ "${_c[@]}" == "one" ]                                       || return 15

  $_func _c &> /dev/null                                        || return 16
  [ ${#_c[@]} -eq 0 ]                                           || return 17 
  ! $_func _c &> /dev/null                                      || return 18 

  ! $_func _c &> /dev/null                                      || return 19
  $_func _c &> /dev/null && _ret=$? || _ret=$?
  [ $_ret -eq 3 ]                                               || return 20
  [ ${#_c[@]} -eq 0 ]                                           || return 21
} && tsh::addFunc test__arrr_popTest

array::popNameTest() {
  local _func="array::popName" _c
  ! $_func                                                      || return 1
  ! $_func _c "one"                                             || return 2
  [ "$($_func _c 'one')" == "" ]                                || return 3
  _c=(one two "three four" four one)
  [ "$($_func _c '')" = "" ]                                    || return 4
  [ "$($_func _c ' ')" = "" ]                                   || return 5
  [ "$($_func _c 'three')" = "" ]                               || return 6
  [ "$($_func _c 'three four ')" = "" ]                         || return 7
  [ "$($_func _c 'three four')" = "three four" ]                || return 8
  $_func _c "three four" &> /dev/null                           || return 9
  [ "$($_func _c 'one')" = "one" ]                              || return 10
  $_func _c "one" &> /dev/null                                  || return 11
  [ ${#_c[@]} -eq 3 ]                                           || return 12
  _c=()
} && tsh::addFunc array::popNameTest

array::uniqueTest() {
  local _func="array::unique"
  [ "$($_func one two)" == "one two" ]                          || return 1
  [ "$($_func one two one three)" == "one two three" ]          || return 2
  [ "$($_func one two 1 one three ' one')" \
      == "one two 1 three  one" ]                               || return 3
  ! [ "$($_func one two 1 one three '  one')" \
      == "one two 1 three  one" ]                               || return 4
} && tsh::addFunc array::uniqueTest
