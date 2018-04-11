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
  #
  [ $# -eq 2 ]                                                  || return 1
  local _arr_name_from _arr_name_to
  _arr_name_from="$1"
  _arr_name_to="$2"

  [ "$_arr_name_from" = "$_arr_name_to" ] \
    && echo "ERROR: Trying to duplicate same array name: '$_arr_name_from' and '$_arr_name_to'." \
                                                                && return 2 \
                                                                || :
  eval "[ \${$_arr_name_from[@]:+x} ]"                          || return 3
  eval "$_arr_name_to=(\"\${$_arr_name_from[@]}\")"             || return 4
}

test__arrr_array_duplicate_from_to() {
  set -u
  local _func="arrr_array_duplicate_from_to" _res _ret
  local _arr1 _arr2
  ! $_func                                                      || return 1
  ! $_func oen two thre                                         || return 2

  _arr1=(one two " three four" five)
  $_func _arr1 _arr2                                            || return 3
  [ ${#_arr2[@]} -eq ${#_arr1[@]} ]                             || return 4
  ! [ "${_arr2[2]}" == " three four " ]                         || return 5
  [ "${_arr2[2]}" == " three four" ]                            || return 6
  ! $_func undefined_array _arr2                                || return 7

  $_func undefined_array _arr2 && _ret=$? || _ret=$?
  [ $_ret -eq 3 ]                                               || return 8

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
  _c=(one thow "three four")
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2
  ! $_func _undefined one two                                   || return 3
  [ ${#_c[@]} -eq 3 ]                                           || return 4
  $_func _c added1 "added 2" added3
  ! [ "${_c[2]}" = "three fou" ]                                || return 5
  [ "${_c[2]}" = "three four" ]                                 || return 6
  [ "${_c[3]}" = "added1" ]                                     || return 7
  [ "${_c[-1]}" = "added3" ]                                    || return 8
  [ ${#_c[@]} -eq 6 ]                                           || return 9
} && tsh__add_func test__arrr_add

function arrr_dump() {
  #
  # Dumps the content of the given array name
  # on new lines.
  #
  local _afrom="$1"; shift # TO wrap with macro
  local _dump_anew=()  # TO wrap with macro
  arrr_array_duplicate_from_to "$_afrom" _dump_anew  # TO wrap with macro
  for elem in "${_dump_anew[@]}"; do printf "$elem\n"; done
}

function arrr_indexes_of() {
  #
  # Takes an array name and returns the indexes 
  # where the given string is found in it.
  # $1: array name
  # $2-: [string ...]
  #
  local _afrom="$1"; shift
  local _indexes_of_anew=()
  arrr_array_duplicate_from_to "$_afrom" _indexes_of_anew  
  
  local tosearch="$1"
  for i in "${!_indexes_of_anew[@]}"; do
    [ "${_indexes_of_anew[$i]}" = "$tosearch" ] \
     && printf "$i\n" \
     || :
  done
}

test__arrr_indexes_of() {
  local _c=(one thow "three four" one)
  [ "$(arrr_indexes_of _c ase | xargs)" = "" ] || return 1
  [ "$(arrr_indexes_of _c 'three four ' | xargs)" = "" ] || return 2
  [ "$(arrr_indexes_of _c 'one' | xargs)" = "0 3" ] || return 3
} && tsh__add_func test__arrr_indexes_of

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
  local _func="arrr_contains" _c=(one thow "three four" one)
  ! $_func                                                      || return 1
  ! $_func _c                                                   || return 2 
  ! $_func _notdefined "one"                                    || return 3
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
  local _afrom="$1"; shift
  local _pop_anew=()
  arrr_array_duplicate_from_to "$_afrom" _pop_anew

  local index="${1:-$(( ${#_pop_anew[@]} -1))}" 
  printf "${_pop_anew[$index]}\n"
  unset '_pop_anew[$index]'
  arrr_array_duplicate_from_to _pop_anew "$_afrom"
}

test__arrr_pop() {
  local _c=(one two "three four" four five)
  local _res
  [ ${#_c[@]} -eq 5 ] || return 1
  [ "$(arrr_pop _c)" = "five" ] || return 2
  ## We popped it in a subshell. We need to do it in this shell:
  arrr_pop _c &> /dev/null
  [ "$(arrr_pop _c 2)" = "three four" ] || return 3
  arrr_pop _c 2 &> /dev/null
  [ ${#_c[@]} -eq 3 ] || return 4
} && tsh__add_func test__arrr_pop

function arrr_pop_name() {
  #
  # Takes an array name and pops its first element 
  # that matches the given string, starting from the end.
  #
  
  local _afrom="$1"; shift # TO wrap with macro
  local _tofind="$1"

  ## Get the indexes
  local _indexes=($(arrr_indexes_of "$_afrom" "$_tofind"))
  local _nb_idx=${#_indexes[@]}
  
  ## Don't do anything if no index found.
  [ $_nb_idx -eq 0 ] && return 0

  ## Pop the first index found
  local _index=${_indexes[$(( _nb_idx -1 ))]}
  arrr_pop "$_afrom" $_index
}

test__arrr_pop_name() {
  local _c=(one two "three four" four one)
  [ "$(arrr_pop_name _c '')" = "" ] || return 1
  [ "$(arrr_pop_name _c ' ')" = "" ] || return 2
  [ "$(arrr_pop_name _c 'three')" = "" ] || return 3
  [ "$(arrr_pop_name _c 'three four ')" = "" ] || return 4
  [ "$(arrr_pop_name _c 'three four')" = "three four" ] || return 5
  arrr_pop_name _c "three four" &> /dev/null
  [ "$(arrr_pop_name _c 'one')" = "one" ] || return 6
  arrr_pop_name _c "one" &> /dev/null
  [ ${#_c[@]} -eq 3 ] || return 7
} && tsh__add_func test__arrr_pop_name
