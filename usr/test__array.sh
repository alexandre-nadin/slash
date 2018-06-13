#!/usr/bin/env bash
source array.sh

test__arrr_array_duplicate_from_to() {
  set -u
  local _func="arrr_array_duplicate_from_to" _res _ret
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

} && tsh__add_func test__arrr_array_duplicate_from_to

test__arrr_add() {
  local _func="arrr_add" _c
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
} && tsh__add_func test__arrr_add

test__arrr_add_unique() {
  local _func="arrr_add_unique" _c
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
} && tsh__add_func test__arrr_add_unique

test__arrr_dump() {
  local _func="arrr_dump" _c
  ! $_func                                                      || return 1
  $_func _c &> /dev/null                                        || return 2
  _c=(one thow "three four")
  [ "$($_func _c)" == "$(printf 'one\nthow\nthree four')" ]     || return 3
} && tsh__add_func test__arrr_dump

test__arrr_indexes_of() {
  local _func="arrr_indexes_of" _c
  _c=(one thow "three four" one)
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2
  ! $_func _undefined                                           || return 3
  [ "$($_func _c ase | xargs)" = "" ]                           || return 4
  [ "$($_func _c 'three four ' | xargs)" = "" ]                 || return 5
  [ "$($_func _c 'one' | xargs)" = "0 3" ]                      || return 6
} && tsh__add_func test__arrr_indexes_of

test__arrr_indexes() {
  local _func="arrr_indexes" _c _indexes
  ! $_func                                                      || return 1
  $_func _c                                                     || return 2

  _c=(one thow "three four" one)
  $_func _c &> /dev/null && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 3

  $_func _c | xargs |
   while IFS= read -r _line; do
     [ "$_line" == "0 1 2 3" ]                                  || return 4
   done
  
} && tsh__add_func test__arrr_indexes

test__arrr_contains() {
  local _func="arrr_contains" _c
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
} && tsh__add_func test__arrr_contains

test__arrr_pop() {
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
} && tsh__add_func test__arrr_pop

test__arrr_pop_name() {
  local _func="arrr_pop_name" _c
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
} && tsh__add_func test__arrr_pop_name
