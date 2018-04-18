#!/usr/bin/env bash
source number.sh

test::is_int() {
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
} && tsh__add_func test::is_int

test::are_int() {
  local _func="are_int" _ret
  ! $_func                                                      || return 1
  $_func 1                                                      || return 2
  $_func 1 2                                                    || return 3
  ! $_func 1 2.4 5                                              || return 4
  ! $_func 1 b 5                                                || return 5
} && tsh__add_func test::are_int

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

test__++() {
  local _func="++" _res _ret _a_nb
  ! $_func                                                      || return 1
  ! $_func 1 2                                                  || return 2
  ! $_func b                                                    || return 3
  ! $_func 3.4                                                  || return 4
  ! $_func 1                                                    || return 5
  ! $_func -5                                                   || return 6
  _a_nb=-6
  $_func _a_nb                                                  || return 7
  [ $_a_nb -eq -5 ]                                             || return 8
  
  $_func _a_nb "8"                                              || return 9
  [ $_a_nb -eq 3 ]                                              || return 10

  $_func _a_nb '-2'                                             || return 11
  [ $_a_nb -eq 1 ]                                              || return 12

  ! $_func _a_nb -2.4                                           || return 13
  ! $_func _a_nb e                                              || return 14
  [ $_a_nb -eq 1 ]                                              || return 15

  $_func _a_nb +5                                               || return 16
  [ $_a_nb -eq 6 ]                                              || return 17
} && tsh__add_func test__++

test__--() {
  local _func="--" _res _ret _a_nb
  ! $_func                                                      || return 1
  ! $_func 1 2                                                  || return 2
  ! $_func b                                                    || return 3
  ! $_func 3.4                                                  || return 4
  ! $_func 1                                                    || return 5
  ! $_func -5                                                   || return 6

  _a_nb=-6
  $_func _a_nb                                                  || return 7
  [ $_a_nb -eq -7 ]                                             || return 8
  
  $_func _a_nb "-8"                                             || return 9
  [ $_a_nb -eq 1 ]                                              || return 10

  $_func _a_nb '-2'                                             || return 11
  [ $_a_nb -eq 3 ]                                              || return 12

  ! $_func _a_nb -2.4                                           || return 13
  ! $_func _a_nb e                                              || return 14
  [ $_a_nb -eq 3 ]                                              || return 15

  $_func _a_nb +5                                               || return 16
  [ $_a_nb -eq -2 ]                                             || return 17
} && tsh__add_func test__--
