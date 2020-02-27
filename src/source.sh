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
function source::resetSources() {
  #
  # Resets the array of unique sourced files.
  #
  [ $# -eq 0 ]                                                  || return 1
  src__sourcedFiles=("$(basename ${BASH_SOURCE[0]})")           || return 2
} && source::resetSources

source::hasSourcedFiles() {
  [ ${#src__sourcedFiles[@]} -eq 0 ]
}

source::containsSource() {
  [ $# -eq 1 ]                                                  || return 1
  source::hasSourcedFiles                                       || return 2
  grep -q -s " $1 " <<< " ${src__sourcedFiles[@]} "             || return 3
}

source::addSource() {
  [ $# -eq 1 ]                                                  || return 1
  src__sourcedFiles+=("$1")
}

source::addSourceUnique() {
  #
  # Adds the given string to a list of tracked files it is does not already
  # exist.
  #
  [ $# -eq 1 ]                                                  || return 1
  ! source::containsSource "$1" \
   && source::addSource "$1"                                    || return 2
}

source::removeSourceUnique() {
  #
  # Removes the given string from the list of tracked files if it exists.
  #
  [ $# -eq 1 ]                                                  || return 1
  source::hasSourcedFiles                                       || return 2
  source::containsSource "$1"                                   || return 3
  local _tmpArr
  for _src in "${src__sourcedFiles[@]}"; do
    [ "$_src" == "$1" ] || _tmpArr+=("$_src") 
  done 
  src__sourcedFiles=($(echo "${_tmpArr[@]}"))                   || return 4

}

# ------------------------------------------------------------------------------ 
# Unique sourcing
#
# 'source::uniqueStrict' is the function that does the unique sourcing. It returns a 
# non-zero value if the sourcing cannot be done. 
#
# ------------------------------------------------------------------------------
source::unique() {
  #
  # Sources the given file only if it has not already been sourced.
  # Return status is always 0, ignoring redundant sourcing.
  #
  source::uniqueStrict "$@" || :
}

source::uniqueStrict() {
  #
  # Sources a file only if it has not already been sourced.
  # Saves the provided file name, sources it, removes it if sourcing fails.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _src="$1" ret=0
  # Strip the file name before (passing without parenthesis)
  source::addSourceUnique $_src                                 || return 2
  if source::cleanSource $_src; then
    return 0
  else
    source::removeSourceUnique $_src                            && return 4 \
                                                                || return 3
  fi
}

source::cleanSource() {
  #
  # Saves the current shell set options before sourcing the given file.
  # Restores them afterwards.
  #
  [ $# -eq 1 ]                                                  || return 1
  local setopts ret=0
  ## Save set opts
  setopts=$(set +o | sed 's/$/;/g')                             || ret=1
  set +o history
  unset HISTFILE
  source "$1"                                                   || ret=2 
  ## Restore set opts
  eval "$setopts"                                               || ret=3
  return $ret
}

source::isFileSourced() {
  #
  # Checks if the sourcing file has been sourced itself.
  # 
  [ $# -ge 0 ]                                                  || return 1
  local _increm_bias=${1:-0}
  _increm_bias=$(( _increm_bias + 1 ))                          || return 2
  [ ${#BASH_SOURCE[@]} -gt 1 ]                                  || return 3
  ! [ "${BASH_SOURCE[${_increm_bias}]}" = "${0}" ]              || return 4 
}
