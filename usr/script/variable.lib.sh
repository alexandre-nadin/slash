#!/usr/bin/env bash
function vars_enum() {
  #
  # Declares and enumerates all the given variable names from 0.
  # 
  local nb=0
  for _var in $@; do
    eval "$_var=$nb"
    nb=$((nb+1))
  done
}

function vars__default_export() {
  #
  # Export variable by default.
  # Can be used to avoid unbound variables error when
  # setting 'set -euf'.
  #
  for _var in $@; do
    eval "export $_var=\${!_var:-}"
  done
}

vars__swap_vars() {
  #
  # Takes two variable names and swaps their content.
  #
  [ $# -eq 2 ]                                                  || return 1
  local _temp="$1"
  eval "$1=${!2} && $2=${!_temp}"                               || return 2
}
