#!/usr/bin/env sh
source logging.lib

function trap_add_func() {
  #
  # Appends the given function to the fiven trap.
  # Assumes a trap is of the form 'func1;func2;...'
  # Mostly inspired from http://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal
  #
  # $1: function name.
  # $@: Traps
  #
  local trap_add_cmd=$1 
  shift \
   || {
       errecho "${FUNCNAME} usage error" 
       return 1
      }
  local new_cmd=
  local existing_cmd=
  for trap_add_name in "$@"; do
    # Grab the currently defined trap commands for this trap
    existing_cmd=$(trap -p "${trap_add_name}" \
                    |  awk -F"'" '{print $2}')

    # Define default command
    [ -z "${existing_cmd:+x}" ] \
     && existing_cmd="" \
     || existing_cmd="${existing_cmd};"

    # Generate the new command
    new_cmd="${existing_cmd}${trap_add_cmd}"

    # Assign the test
    trap "${new_cmd}" "${trap_add_name}" \
     || { 
         errecho "Unable to add to trap ${trap_add_name}"
         return 1
        }
  done
}
