#!/usr/bin/env bash

is_int() {
  #
  # Checks if the given number is an integer.
  #
  [ $# -eq 1 ]                                                  || return 1
  ([ $1 -ge 0 &> /dev/null ] || [ $1 -le 0 &> /dev/null ])      || return 2
}

are_int() {
  #
  # Checks whether the given numbers are integer.
  #
  [ $# -gt 0 ]                                                  || return 1
  for _nb in "$@"; do
    is_int $_nb                                                 || return 2
  done
}

int_is_in_range() {
  #
  # Checks if $1 is between $2 and $3.
  #
  [ $# -eq 3 ]                                                  || return 1
  are_int "$@"                                                  || return 2
  [ $1 -ge $2 -a $1 -le $3 ]                                    || return 3
}

++() {
  #
  # Takes a variable name pointing to an int and increments it by the specified
  # integer if any. Default increment is 1.
  #
  int_is_in_range $# 1 2                                        || return 1
  local _var _incr
  _var="$1"
  _incr="${2:-1}"
  ! is_int ${_var}                                              || return 2
  is_int ${!_var}                                               || return 3
  is_int $_incr                                                 || return 4
  eval "${_var}=$(( ${!_var} + $_incr ))"                       || return 5
}

--() {
  #
  # Takes a variable name pointing to an int and decrements it by the specified
  # integer if any. Default decrement is 1.
  #
  int_is_in_range $# 1 2                                        || return 1
  local _var _decr _sign
  _var="$1"
  _decr="${2:-1}"
  ! is_int ${_var}                                              || return 2
  is_int ${!_var}                                               || return 3
  is_int $_decr                                                 || return 4
  eval "${_var}=$(( ${!_var} - $_decr ))"                       || return 5
}
