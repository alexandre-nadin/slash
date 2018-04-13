#!/usr/bin/env bash

function nb_is_in_range() {
  #
  # Checks if $1 is between $2 and $3.
  #
  [ "$1" -ge "$2" -a "$1" -le "$3" ] \
   && return 0 \
   || return 1
}
