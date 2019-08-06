#!/usr/bin/env bash

grep__lineNumber() {
  local _pattern _input
  [ $# -gt 0 ] || return 1
  _pattern="$1" && shift
  _input="${1:-$(io_existing_stdin)}"
  grep -n "$_pattern" <<< "$_input" \
   | cut -f1 -d:
}

