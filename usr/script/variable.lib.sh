#!/usr/bin/env bash
#source testsh.lib

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

test__enum() {
  local _func="vars_enum" _enum_vars
  vars_enum OK FIRST SECOND THIRD FOURTH                        || return 1
  # FIRST should be defined
  [ "${FIRST:+x}" ]                                             || return 2
  [ -z "${FIRS:+x}" ]                                           || return 3
  [ $FIRST == "1" ]                                             || return 4
  [ $OK -eq 0 ]                                                 || return 5
} #&& tsh__add_func test__enum

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
  [ $# -eq 2 ] || return 1
  local _temp="$1"
  eval "$1=${!2} && $2=${!_temp}" || return 2
}

test__swap_vars() {
  local _func="vars__swap_vars"
  local one=1 two=2
  $_func ; [ $? -eq 1 ]               || return 1
  $_func one; [ $? -eq 1 ]            || return 2
  [ "$one" == "1" ]                   || return 3
  [ "$two" == "2" ]                   || return 4
  $_func one two                      || return 5
  [ "$one" == "2" ]                   || return 6
  [ "$two" == "1" ]                   || return 7
}

