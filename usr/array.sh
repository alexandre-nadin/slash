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
 
function arrr_add_unique() {
  #
  # Takes an array name and add the given element to it if it does not exist.
  #
  [ $# -eq 2 ]                                                  || return 1
  local _afrom _anew _elem
  _afrom="$1"  && shift
  _elem="$1" 
  
  ## Exits if _elem already exists
  ! arrr_contains "$_afrom" "$_elem"                            || return 2
  arrr_add "$_afrom" "$_elem"                                   || return 3
}

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
  unset '_atemp[$_index]'                                       || return 6
  arrr_array_duplicate_from_to _atemp "$_afrom"                 || return 7
}

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
  
  ## Return error if no index found
  ! [ $_nb_idx -eq 0 ]                                          || return 4

  ## Pop the first index found
  _index=${_indexes[$(( _nb_idx -1 ))]}
  arrr_pop "$_afrom" $_index                                    || return 5
}

function arrr_set() {
  #
  # Takes input elements and returns a set.
  # A set here is still an array of unique element.
  #
  [ $# -gt 0 ]                                                  || return 0
  local _set=()
  for _e in "$@"; do
    arrr_add_unique _set "$_e" 
  done
  pecho "${_set[@]}"
}
