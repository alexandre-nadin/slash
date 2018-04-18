#!/usr/bin/env bash
source variable.lib

test__enum() {
  local _func="vars_enum" _enum_vars
  vars_enum OK FIRST SECOND THIRD FOURTH                        || return 1
  # FIRST should be defined
  [ "${FIRST:+x}" ]                                             || return 2
  [ -z "${FIRS:+x}" ]                                           || return 3
  [ $FIRST == "1" ]                                             || return 4
  [ $OK -eq 0 ]                                                 || return 5
} && tsh__add_func test__enum

test__swap_vars() {
  local _func="vars__swap_vars"
  local one=1 two=2
  $_func ; [ $? -eq 1 ]                                         || return 1
  $_func one; [ $? -eq 1 ]                                      || return 2
  [ "$one" == "1" ]                                             || return 3
  [ "$two" == "2" ]                                             || return 4
  $_func one two                                                || return 5
  [ "$one" == "2" ]                                             || return 6
  [ "$two" == "1" ]                                             || return 7
} && tsh__add_func test__swap_vars
