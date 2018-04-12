#!/usr/bin/env bash
#
# This library is designed to manipulate arrays via the use
# of the array reference (name) only.
# So all functions expect an array name, not array content.
# Of course each array name should be defined in the current
# shell environment.
#
#
source testsh.lib

function arrr_array_duplicate_from_to() {
  #
  # Takes the names of two arrays defined in the current env.
  # Duplicates the first one into the second one. 
  # If first is empty, duplicate it as an empty array.
  #
  [ $# -eq 2 ]                                                  || return 1
  local _afrom _ato _afrom_empty
  _afrom="$1"
  _ato="$2"

  [ "$_afrom" = "$_ato" ] \
    && echo "ERROR: Trying to duplicate same array name: '$_afrom' and '$_ato'." \
                                                                && return 2 \
                                                                || :
  ## Check origin array is not empty
  eval "[ \${$_afrom[@]:+x} ]" \
   && _afrom_empty=false \
   || _afrom_empty=true   
 
  if $_afrom_empty; then
    eval "$_ato=()"                                             || return 3
  else
    eval "$_ato=(\"\${$_afrom[@]}\")"                           || return 4
  fi
}

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


function arrr_add() {
  #
  # Takes an array name and adds the given element to it.
  #
  [ $# -ge 2 ]                                                  || return 1
  local _afrom _add_anew 
  _afrom="$1"                                          && shift || return 2
  _add_anew=()
  arrr_array_duplicate_from_to "$_afrom" _add_anew              || return 3
  for _elem in "$@"; do _add_anew+=("$_elem"); done
  arrr_array_duplicate_from_to _add_anew "$_afrom"              || return 4
}
 
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

function arrr_add_unique() {
  #
  # Takes an array name and add the given element to it if it does not exist.
  #
  [ $# -eq 2 ]                                       || return 1
  local _afrom _anew _elem
  _afrom="$1"  && shift
  _elem="$1" 
  
  ## Exits if _elem already exists
  ! arrr_contains "$_afrom" "$_elem"                      || return 2
  arrr_add "$_afrom" "$_elem"           || return 3
}

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

function arrr_dump() {
  #
  # Dumps the content of the given array name
  # on new lines.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _afrom _dump_anew
  _afrom="$1"                                                   || return 2
  _dump_anew=()
  arrr_array_duplicate_from_to "$_afrom" _dump_anew             || return 3
  for _elem in "${!_dump_anew[@]}"; do 
    printf "${_dump_anew[$_elem]}\n"; 
  done
}

test__arrr_dump() {
  local _func="arrr_dump" _c
  ! $_func                                                      || return 1
  $_func _c &> /dev/null                                        || return 2
  _c=(one thow "three four")
  [ "$($_func _c)" == "$(printf 'one\nthow\nthree four')" ]     || return 3
} && tsh__add_func test__arrr_dump

function arrr_indexes_of() {
  #
  # Takes an array name and returns the indexes 
  # where the given string is found in it.
  # $1: array name
  # $2-: [string ...]
  #
  local _afrom _tosearch _indexes_of_anew
  [ $# -ge 2 ]                                                  || return 1
  _afrom="$1"                                          && shift || return 2
  _tosearch="$1"
  arrr_array_duplicate_from_to "$_afrom" _indexes_of_anew       || return 3
  
  for _i in "${!_indexes_of_anew[@]}"; do
    [ "${_indexes_of_anew[$_i]}" = "$_tosearch" ] \
     && printf "$_i\n" \
     || :
  done
}

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

function arrr_indexes() {
  #
  # Returns a list of indexes of the given array name.
  # If the array is emptu or undefined, there are no indexes. 
  # Returns either a non-empty list of indexes or an error.
  # For now it is a bit useless since this function would be used
  # in a subshell, losing the function's declaration.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _afrom _anew
  _afrom="$1"
  arrr_array_duplicate_from_to "$_afrom" _anew                  || return 2
  for _i in "${!_anew[@]}"; do
    printf "${_i}\n"
  done
}

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

function arrr_contains() {
  #
  # Finds if an element is present in the given array name.
  # $1: array name
  # $2: element
  #
  [ $# -eq 2 ]                                                  || return 1
  local _afrom _tofind _indexes _nb_idx
  _afrom="$1"                                          && shift || return 2
  _tofind="$1"
 
  ## Get the indexes
  _indexes=($(arrr_indexes_of "$_afrom" "$_tofind"))            || return 3
  [ ${#_indexes[@]} -ne 0 ]                                     || return 4
}

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

function arrr_pop() {
  #
  # Takes an array name and pops its element 
  # at the given position index. 
  # Indexes start from 0.
  # Default index is the array's last element's
  #
  [ $# -ge 1 ]                                                  || return 1
  local _afrom _atemp _atemp_size _indexes _index 
  _afrom="$1"; shift
  _atemp=()
  arrr_array_duplicate_from_to "$_afrom" _atemp                 || return 2
  _atemp_size=${#_atemp[@]}
  ## Array size must be > 0
  [ $_atemp_size -gt 0 ]                                        || return 3

  ## Requested index
  _index="${1:-$(( $_atemp_size -1))}"
  
  ## Check index is not out of bound
  if [ $_index -ge 0 ]; then
    [ $(( _atemp_size - _index )) -ge 1 ]                       || return 4
  else
    [ $(( _atemp_size + _index )) -ge 0 ]                       || return 5
  fi

  printf "${_atemp[$_index]}\n"
  unset '_atemp[$_index]'
  arrr_array_duplicate_from_to _atemp "$_afrom"                 || return 6
}

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

function arrr_pop_name() {
  #
  # Takes an array name and pops its first element 
  # that matches the given string, starting from the end.
  #
  [ $# -eq 2 ]                                                  || return 1 
  local _afrom _tofind _indexes _nb_idx _index
  _afrom="$1"                                          && shift || return 2
  _tofind="$1"

  ## Get the indexes
  _indexes=($(arrr_indexes_of "$_afrom" "$_tofind"))            || return 3
  _nb_idx=${#_indexes[@]}
  
  ## Don't do anything if no index found.
  ! [ $_nb_idx -eq 0 ]                                          || return 0

  ## Pop the first index found
  _index=${_indexes[$(( _nb_idx -1 ))]}
  arrr_pop "$_afrom" $_index                                    || return 4
}

test__arrr_pop_name() {
  local _func="arrr_pop_name" _c
  ! $_func                                                      || return 1
  $_func _c "one"                                               || return 2
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
