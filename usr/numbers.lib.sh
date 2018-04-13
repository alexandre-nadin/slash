#!/usr/bin/env bash
source testsh.lib

is_integer() {
  #
  # Checks if the given number is an integer.
  #
  [ $# -eq 1 ]                                                  || return 1
  ([ $1 -ge 0 &> /dev/null ] || [ $1 -le 0 &> /dev/null ])      || return 2
}

test__is_integer() {
  local _func="is_integer" _ret
  ! $_func                                                      || return 1
  ! $_func 1 2                                                  || return 2
  $_func 1                                                      || return 3
  $_func 100                                                    || return 4
  $_func 0                                                      || return 5
  $_func -0                                                     || return 6
  $_func -5                                                     || return 7
  $_func -1000                                                  || return 8
  ! $_func 0.2                                                  || return 9
  ! $_func 1.9                                                  || return 10
  ! $_func -2.5                                                 || return 11
} && tsh__add_func test__is_integer

function nb_is_in_range() {
  #
  # Checks if $1 is between $2 and $3.
  #
  [ "$1" -ge "$2" -a "$1" -le "$3" ] \
                                                                && return 0 \
                                                                || return 1
}
