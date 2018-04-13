#!/usr/bin/env bash
source testsh.lib

is_int() {
  #
  # Checks if the given number is an integer.
  #
  [ $# -eq 1 ]                                                  || return 1
  ([ $1 -ge 0 &> /dev/null ] || [ $1 -le 0 &> /dev/null ])      || return 2
}

test__is_int() {
  local _func="is_int" _ret
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
} && tsh__add_func test__is_int

are_int() {
  #
  # Checks whether the given numbers are integer.
  #
  [ $# -gt 0 ]                                                  || return 1
  for _nb in "$@"; do
    is_int $_nb                                                 || return 2
  done
}

test__are_int() {
  local _func="are_int" _ret
  ! $_func                                                      || return 1
  $_func 1                                                      || return 2
  $_func 1 2                                                    || return 3
  ! $_func 1 2.4 5                                              || return 4
  ! $_func 1 b 5                                                || return 5
} && tsh__add_func test__are_int

int_is_in_range() {
  #
  # Checks if $1 is between $2 and $3.
  #
  [ $# -eq 3 ]                                                  || return 1
  are_int "$@"                                                  || return 2
  [ $1 -ge $2 -a $1 -le $3 ]                                    || return 3
}

test__int_is_in_range() {
  local _func="int_is_in_range" _ret
  ! $_func                                                      || return 1
  ! $_func 1                                                    || return 2
  ! $_func 1 2                                                  || return 3
  $_func 3 1 5                                                  || return 4
  ! $_func 3 1 2                                                || return 5
  $_func 1 -1 1                                                 || return 6
  $_func 1 1 1                                                  || return 7
  ! $_func 1.3 0 10                                             || return 8
  $_func 0 -10 25                                               || return 9
  ! $_func b -10 25                                             || return 10
  $_func "0" "-10" "25"                                         || return 11
} && tsh__add_func test__int_is_in_range
