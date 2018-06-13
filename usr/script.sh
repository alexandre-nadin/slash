#!/usr/bin/env bash
source source.sh

shopt -s expand_aliases
alias rexit="is_sourced                                         && return 6    \
                                                                || exit 7"
retexit() {
  #
  # Returns the given value if the current file was sourced.
  # Else exits with the given value.
  # If no value is given, return status is 0.
  #
  local _value="${1:-0}"
  is_sourced                                                    && return $_value \
                                                                || exit $_value
}
