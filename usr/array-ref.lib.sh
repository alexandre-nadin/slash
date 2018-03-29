#!/usr/bin/env bash
#
# This library is designed to manipulate arrays via the use
# of the array reference (name) only.
# So all functions expect an array name, not array content.
# Of course each array name should be defined in the current
# shell environment.
#
#
function arrr_array_duplicate_from_to() {
  #
  # Takes the names of two arrays defined in the current env.
  # Duplicates the first one into the second one. 
  #
  local arr_name_from="$1"
  local arr_name_to="$2"
  [ "$arr_name_from" = "$arr_name_to" ] \
    && echo "ERROR: Trying to duplicate same array name: '$arr_name_from' and '$arr_name_to'." \
    && return 1 \
    || :
    
  local astr="$arr_name_to=(\"\${$arr_name_from[@]}\")"
  eval $astr
}

function arrr_add() {
  #
  # Takes an array name and adds the given element to it.
  #
  local afrom="$1"; shift
  local _add_anew=()
  arrr_array_duplicate_from_to "$afrom" _add_anew
  for elem in "$@"; do _add_anew+=("$elem"); done
  arrr_array_duplicate_from_to _add_anew "$afrom"
}

_test_arrr_add() {
  local _c=(one thow "three four")
  [ ${#_c[@]} -eq 3 ] || return 1
  arrr_add _c added1 "added 2" added3
  [ ! "${_c[2]}" = "three fou" ] || return 2
  [ "${_c[2]}" = "three four" ] || return 3
  [ ${#_c[@]} -eq 6 ] || return 4
}

function arrr_dump() {
  #
  # Dumps the content of the given array name
  # on new lines.
  #
  local afrom="$1"; shift # TO wrap with macro
  local _dump_anew=()  # TO wrap with macro
  arrr_array_duplicate_from_to "$afrom" _dump_anew  # TO wrap with macro
  for elem in "${_dump_anew[@]}"; do printf "$elem\n"; done
}

function arrr_indexes_of() {
  #
  # Takes an array name and returns the indexes 
  # where the given string is found in it.
  # $1: array name
  # $2-: [string ...]
  #
  local afrom="$1"; shift
  local _indexes_of_anew=()
  arrr_array_duplicate_from_to "$afrom" _indexes_of_anew  
  
  local tosearch="$1"
  for i in "${!_indexes_of_anew[@]}"; do
    [ "${_indexes_of_anew[$i]}" = "$tosearch" ] \
     && printf "$i\n" \
     || :
  done
}

_test_arrr_indexes_of() {
  local _c=(one thow "three four" one)
  [ "$(arrr_indexes_of _c ase | xargs)" = "" ] || return 1
  [ "$(arrr_indexes_of _c 'three four ' | xargs)" = "" ] || return 2
  [ "$(arrr_indexes_of _c 'one' | xargs)" = "0 3" ] || return 3
}

function arrr_contains() {
  #
  # Finds if an element is present in the given array name.
  # $1: array name
  # $2: element
  #
  local afrom="$1"; shift # TO wrap with macro
  local _tofind="$1"

  ## Get the indexes
  local _indexes=($(arrr_indexes_of "$afrom" "$_tofind"))
  local _nb_idx=${#_indexes[@]}
  
  ## Don't do anything if no index found.
  [ $_nb_idx -eq 0 ] \
   && return 1 \
   || return 0
}

_test_arrr_contains() {
  local _c=(one thow "three four" one)
  ! arrr_contains _c ase || return 1
  ! arrr_contains _c 'three four ' || return 2
  arrr_contains _c 'one' || return 3
  ! arrr_contains _c "" || return 4
  ! arrr_contains _c " " || return 5
}

function arrr_pop() {
  #
  # Takes an array name and pops its element 
  # at the given position index. 
  # Indexes start from 0.
  # Default index is the array's last element's
  #
  local afrom="$1"; shift
  local _pop_anew=()
  arrr_array_duplicate_from_to "$afrom" _pop_anew

  local index="${1:-$(( ${#_pop_anew[@]} -1))}" 
  printf "${_pop_anew[$index]}\n"
  unset '_pop_anew[$index]'
  arrr_array_duplicate_from_to _pop_anew "$afrom"
}

_test_arrr_pop() {
  local _c=(one two "three four" four five)
  local _res
  [ ${#_c[@]} -eq 5 ] || return 1
  [ "$(arrr_pop _c)" = "five" ] || return 2
  ## We popped it in a subshell. We need to do it in this shell:
  arrr_pop _c &> /dev/null
  [ "$(arrr_pop _c 2)" = "three four" ] || return 3
  arrr_pop _c 2 &> /dev/null
  [ ${#_c[@]} -eq 3 ] || return 4
}

function arrr_pop_name() {
  #
  # Takes an array name and pops its first element 
  # that matches the given string, starting from the end.
  #
  
  local afrom="$1"; shift # TO wrap with macro
  local _tofind="$1"

  ## Get the indexes
  local _indexes=($(arrr_indexes_of "$afrom" "$_tofind"))
  local _nb_idx=${#_indexes[@]}
  
  ## Don't do anything if no index found.
  [ $_nb_idx -eq 0 ] && return 0

  ## Pop the first index found
  local _index=${_indexes[$(( _nb_idx -1 ))]}
  arrr_pop "$afrom" $_index
}

_test_arrr_pop_name() {
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
}

_arrr_tests=(
  _test_arrr_add
  _test_arrr_indexes_of
  _test_arrr_pop
  _test_arrr_pop_name
  _test_arrr_contains
)

_test_arrr() {
  local _status=0
  for test in "${_arrr_tests[@]}"; do
    printf "Testing $test" >&2
    $test \
     && printf "\tv OK\n" >&2 \
     || {
         printf "\tx KO ($?)\n" >&2 \
          && _status=1
        }
  done
  return $_status
}
