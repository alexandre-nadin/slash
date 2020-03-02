#!/usr/bin/env bash
source source.sh

shopt -s expand_aliases
alias script::rexit="source::isFileSourced && return 6 || exit 7"

script::returnOrExit() {
  #
  # Returns the given value if the current file was sourced.
  # Else exits with the given value.
  # If no value is given, return status is 0.
  #
  local _value="${1:-0}"
  source::isFileSourced && return $_value || exit $_value
}
