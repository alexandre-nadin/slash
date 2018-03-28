#!/usr/bin/env bash
source logging.lib
source variable.lib
source functions.lib


# ------
# STDIN
# ------
_stdin_types=(IO_STDIN_TERMINAL IO_STDIN_PIPE IO_STDIN_REDIRECTED)
## Declare and enum the types
vars_enum ${_stdin_types[@]}

function.public std_types() {
  #
  # Displays the STDIN types.
  #
  for _type in "${_stdin_types[@]}"; do
    printf "${_type}: ${!_type}\n"
  done
}

function.public io_which_stdin() {
  #
  # Returns type of STDIN.
  # Check all the type with function 'stdin_types'.
  #
  if [[ -p /dev/stdin ]]; then
    debugecho "stdin is coming from a pipe"
    printf "${IO_STDIN_PIPE}\n" \
     && return 0
  fi
  if [[ -t 0 ]]; then
    debugecho "stdin is coming from the terminal"
    printf "${IO_STDIN_TERMINAL}\n" \
     && return 0
  fi
  if [[ ! -t 0 && ! -p /dev/stdin ]]; then
    debugecho "stdin is redirected"
    printf "${IO_STDIN_REDIRECTED}\n" \
     && return 0
  fi
}

## Declare functions <is_STDIN_TYPE> for each type of stdin.
function.public io_is_IO_STDIN_TERMINAL() {
  # No pipe, wait for stdin 
  [ $(io_which_stdin) -eq $IO_STDIN_TERMINAL ] && return 0 || return 1
}

function.public io_is_IO_STDIN_PIPE() {
  # | or < <()
  [ $(io_which_stdin) -eq $IO_STDIN_PIPE ] && return 0 || return 1
}

function.public io_is_IO_STDIN_REDIRECTED() {
  # < or <<<
  [ $(io_which_stdin) -eq $IO_STDIN_REDIRECTED ] && return 0 || return 1
}

## Get stdin
function.public io_existing_stdin() {
  #
  # Echoes the content of stdin only if not empty.
  #
  io_is_IO_STDIN_PIPE \
   || io_is_IO_STDIN_REDIRECTED \
   || return 0
  io_stdin
}

function.public io_stdin() {
  #
  # Gets available standard input.
  # Waits for input if empty.
  #
  cat /dev/stdin
}

## Get stdin lines
io_stdin_lines=()
function.public io_save_stdin_lines() {
  #
  # Saves stdin in variable io_stdin_lines.
  #
  mapfile -t io_stdin_lines < <(io_stdin)
}

function.public io_save_existing_stdin_lines() {
  #
  # Saves stdin, if not empty, in io_stdin_lines.
  #
  mapfile -t io_stdin_lines < <(io_existing_stdin)
}
