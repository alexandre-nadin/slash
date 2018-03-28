#!/usr/bin/env sh

# -------------
# PID library
# -------------
function pid_pids_status() {
  #
  # Gets PIDs' exit status.
  # Implies the PIDs are subshells of this process.
  # If PIDs are not over, wait for them.
  #
  local pids=($@)
  local pid_exit_stats=()
  local pid_exit_stat=0
  local exit_stat=0
  for pid in ${pids[@]}; do
    wait "$pid"
    pid_exit_stat=$?
    pid_exit_stats+=($pid_exit_stat)
  done
  echo "${pid_exit_stats[@]}"
}

function pid_pids_ok() {
  #
  # Takes a list of pids and returns non-zero if 
  # one exited with a status different than 0. 
  #
  for _status in "$@"; do
    [ "$_status" -eq 0 ] \
     || return 1
  done
}
