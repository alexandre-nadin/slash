#!/usr/bin/env bash
#
# This library is designed to manipulate arrays via the use
# of the array reference (name) only.
# So all functions expect an array name, not array content.
# Each array name should be defined in the current
# shell environment.
#
# !! WARNING
# There is a flaw to that library. Since array names are passed to functions
# and array manipulations rely on Bash indirect expansions, we often need to 
# duplicate the input array name into the function's local array. The latter
# will be manipulated in the function scope.
# Unexpected behaviours may arise when the (global) input array name equals the
# local array name. The (global) input array will be resetted with the
# declaration of the local array. I am not sure how to circumvent that.
# The workaround for now is to give the local array a specific and
# improbable name, such as:
#
#   array::task() {
#     local aFrom="$1" _aToTask=()
#   }
#
# Here the local array name first begins with an underscore, and ends with the
# name of the function. I am definitely not satisfied with this.
# However an error is given when global and local array names match.
# Another solution is passing array values to functions works, but is 
# impractical when the function requires extra parameters.
# 
#
array::duplicateFromTo() {
  #
  # Takes the names of two arrays defined in the current env.
  # Duplicates the first one into the second one. 
  # If first is empty, duplicate it as an empty array.
  #
  [ $# -eq 2 ]                                                  || return 1
  local aFrom _aToDuplicate aFromEmpty
  aFrom="$1"
  _aToDuplicate="$2"
  [ "$aFrom" = "$_aToDuplicate" ] \
    && echo "ERROR: Trying to duplicate same array name: '$aFrom' and '$_aToDuplicate'." >&2 \
                                                                && return 2 \
                                                                || :
  ## Check origin array is not empty
  eval "[ \${$aFrom[@]:+x} ]" \
   && aFromEmpty=false \
   || aFromEmpty=true   
 
  if $aFromEmpty; then
    eval "$_aToDuplicate=()"                                    || return 3
  else
    eval "$_aToDuplicate=(\"\${$aFrom[@]}\")"                   || return 4
  fi
}

array::add() {
  #
  # Takes an array name and adds the given element to it.
  #
  [ $# -ge 2 ]                                                  || return 1
  local aFrom _aToAdd 
  aFrom="$1" && shift                                           || return 2
  _aToAdd=()
  array::duplicateFromTo "$aFrom" _aToAdd                       || return 3
  for elem in "$@"; do _aToAdd+=("$elem"); done
  array::duplicateFromTo _aToAdd "$aFrom"                       || return 4
}
 
array::addUnique() {
  #
  # Takes an array name and add the given element to it if it does not exist.
  #
  [ $# -eq 2 ]                                                  || return 1
  local aFrom elem
  aFrom="$1"  && shift
  elem="$1" 
  
  ## Exits if elem already exists
  ! array::contains "$aFrom" "$elem"                            || return 2
  array::add "$aFrom" "$elem"                                   || return 3
}

array::dump() {
  #
  # Dumps the content of the given array name
  # on new lines.
  #
  [ $# -eq 1 ]                                                  || return 1
  local aFrom _aToDump
  aFrom="$1"                                                    || return 2
  _aToDump=()
  array::duplicateFromTo "$aFrom" _aToDump                      || return 3
  for elem in "${!_aToDump[@]}"; do 
    printf "${_aToDump[$elem]}\n"; 
  done
}

array::indexesOf() {
  #
  # Takes an array name and returns the indexes 
  # where the given string is found in it.
  # $1: array name
  # $2-: [string ...]
  #
  local aFrom strSearch indexes
  [ $# -ge 2 ]                                                  || return 1
  aFrom="$1" && shift                                           || return 2
  strSearch="$1"
  array::duplicateFromTo "$aFrom" indexes                       || return 3
  
  for _i in "${!indexes[@]}"; do
    [ "${indexes[$_i]}" = "$strSearch" ] \
     && printf "$_i\n" \
     || :
  done
}

array::indexes() {
  #
  # Returns a list of indexes of the given array name.
  # If the array is empty or undefined, there are no indexes. 
  # Returns either a non-empty list of indexes or an error.
  # For now it is a bit useless since this function would be used
  # in a subshell, losing the function's declaration.
  #
  [ $# -eq 1 ]                                                  || return 1
  local aFrom _aToIndexes
  aFrom="$1"
  array::duplicateFromTo "$aFrom" _aToIndexes                   || return 2
  for _i in "${!_aToIndexes[@]}"; do
    printf "${_i}\n"
  done
}

array::contains() {
  #
  # Finds if an element is present in the given array name.
  # $1: array name
  # $2: element
  #
  [ $# -eq 2 ]                                                  || return 1
  local aFrom elem indexes
  aFrom="$1" && shift                                           || return 2
  elem="$1"
 
  ## Get the indexes
  indexes=($(array::indexesOf "$aFrom" "$elem"))                || return 3
  [ ${#indexes[@]} -ne 0 ]                                      || return 4
}

arrr_pop() {
  #
  # Takes an array name and pops its element 
  # at the given position index. 
  # Indexes start from 0.
  # Default index is the array's last element's
  #
  [ $# -ge 1 ]                                                  || return 1
  local aFrom _aTempPop aTempPopSize index 
  aFrom="$1"; shift
  _aTempPop=()
  array::duplicateFromTo "$aFrom" _aTempPop                     || return 2
  aTempPopSize=${#_aTempPop[@]}
  ## Array size must be > 0
  [ $aTempPopSize -gt 0 ]                                       || return 3

  ## Requested index
  index="${1:-$(( $aTempPopSize -1))}"
 
  ## Check index is not out of bound
  if [ $index -ge 0 ]; then
    [ $(( aTempPopSize - index )) -ge 1 ]                       || return 4
  else
    [ $(( aTempPopSize + index )) -ge 0 ]                       || return 5
  fi
  printf "${_aTempPop[$index]}\n"
  unset '_aTempPop[$index]'                                     || return 6
  array::duplicateFromTo _aTempPop "$aFrom"                     || return 7
}

array::popName() {
  #
  # Takes an array name and pops its first element 
  # that matches the given string, starting from the end.
  #
  [ $# -eq 2 ]                                                  || return 1 
  local aFrom elem indexes nbIndexes index
  aFrom="$1" && shift                                           || return 2
  elem="$1"

  ## Get the indexes
  indexes=($(array::indexesOf "$aFrom" "$elem"))                || return 3
  nbIndexes=${#indexes[@]}
  
  ## Return error if no index found
  ! [ $nbIndexes -eq 0 ]                                        || return 4

  ## Pop the first index found
  index=${indexes[$(( nbIndexes -1 ))]}
  arrr_pop "$aFrom" $index                                      || return 5
}

array::unique() {
  #
  # Takes input elements and returns a set.
  # A set here is still an array of unique element.
  #
  [ $# -gt 0 ]                                                  || return 0
  local _aToUnique=()
  for _e in "$@"; do
    array::addUnique _aToUnique "$_e" 
  done
  array::print _aToUnique
}

array::print() {
  #
  # Takes an array name and prints its content.
  #
  [ $# -eq 1 ]                                                  || return 1
  local aFrom="$1" _aTempPrint=()
  array::duplicateFromTo "$aFrom" _aTempPrint                   || return 2
  if [ ${#_aTempPrint[@]} -gt 0 ]; then
    printf %s "${_aTempPrint[0]}"
  fi
  arrr_pop _aTempPrint 0 &> /dev/null
  if [ ${#_aTempPrint[@]} -gt 0 ]; then
    printf ' %s' "${_aTempPrint[@]}"
  fi
  printf '\n'
}
