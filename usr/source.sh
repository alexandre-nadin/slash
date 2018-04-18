#!/usr/bin/env bash

# ----------------------------------------------------------------------------
# Self Sourcing. 
#
# My choice is that this library cannot be sourced more than
# once in the same process.
# ----------------------------------------------------------------------------
src__SOURCED=${src__SOURCED:-false}
if $src__SOURCED; then 
  return 0
else 
  src__SOURCED=true
fi

# --------------------------
# Unique sourcing of files
# --------------------------
src__SOURCED_PREFIX="_srced__"

reset_unique_source_files() {
  #
  # Resets the array of unique sourced files.
  #
  [ $# -eq 0 ]                                                  || return 1
  src__sourced_files=("$(basename ${BASH_SOURCE[0]})")          || return 2 
} && reset_unique_source_files

is_source_list_empty() {
  [ ${#src__sourced_files[@]} -eq 0 ]
}

contains_source() {
  [ $# -eq 1 ]                                                  || return 1
  ! is_source_list_empty                                        || return 2
  grep -q -s " $1 " <<< " ${src__sourced_files[@]} "            || return 3
}

add_source() {
  [ $# -eq 1 ]                                                  || return 1
  src__sourced_files+=("$1")
}

add_unique_source() {
  #
  # Adds the given string to a list of tracked files it is does not already
  # exist.
  #
  [ $# -eq 1 ]                                                  || return 1
  ! contains_source "$1" \
   && add_source "$1"                                           || return 2
}

remove_unique_source() {
  #
  # Removes the given string from the list of tracked files if it exists.
  #
  [ $# -eq 1 ]                                                  || return 1
  ! is_source_list_empty                                        || return 2
  contains_source "$1"                                          || return 3
  local _tmp_arr
  for _src in "${src__sourced_files[@]}"; do
    [ "$_src" == "$1" ] \
     || _tmp_arr+=("$_src") 
  done 
  src__sourced_files=($(echo "${_tmp_arr[@]}"))                 || return 4

}

# ------------------------------------------------------------------------------ 
# Unique sourcing
#
# 'unique_source' is the function that does the unique sourcing. It returns a 
# non-zero value if the sourcing cannot be done. It is used for the tests.
# 'usource' and 'source::unique_strict' are the kindof front-end functions call 
# 'unique_source'. Those may be used in your script. 'source::unique' does the same
# except if always returns 0. Use with caution then, with tested scripts and librares. 
#
# ------------------------------------------------------------------------------
usource() {
  unique_source "$@"                                            || return $?
}

source::unique() {
  #
  # Sources the given file only if it has not already been sourced.
  # Return status is always 0, to be used for ignoring redundant sourcing.
  # Use if you are sure the library required do exist and are tested.
  #
  unique_source "$@" || :
}

source::unique_strict() {
  #
  # Sources the given file only if it has not already been sourced.
  # Return error status if it cannot source it.
  #
  unique_source "$@"                                            || return $?
} 

unique_source() {
  #
  # Sources a file only if it has not already been sourced.
  # Save the provided file name.
  # Sources it. Removes it if sourcing failes.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _src="$1" _ret=0
  # Strip the file name before (passing without parenthesis)
  add_unique_source $_src                                       || return 2
  if safe_source $_src; then
    return 0
  else
    remove_unique_source $_src                                  && return 4 \
                                                                || return 3
  fi
}

safe_source() {
  #
  # Saves the current shell set options before sourcing the given file.
  # Restores them afterwards.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _setoptions _ret
  _ret=0
  _setoptions=$(set +o | sed 's/$/;/g')  || _ret=1
  set +o history
  unset HISTFILE
  source "$1" || _ret=2 
  eval "$_setoptions" || _ret=3
  return $_ret
}

is_sourced() {
  #
  # Checks if the sourcing file has been sourced itself.
  # 
  [ $# -ge 0 ]                                                  || return 1
  local _increm_bias=${1:-0}
  _increm_bias=$(( _increm_bias + 1 ))                          || return 2
  [ ${#BASH_SOURCE[@]} -gt 1 ]                                  || return 3
  ! [ "${BASH_SOURCE[${_increm_bias}]}" = "${0}" ]              || return 4 
}
