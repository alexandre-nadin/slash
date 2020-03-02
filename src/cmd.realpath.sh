#!/usr/bin/env bash

source logging.lib
source datetime.lib
# verbecho, errecho, infecho, etc.

function _dotests() {
  echo "Running tests..."
  _test_1
  _test_2
  return 7
}

function man() {
cat << EOFMAN
 
  DESCRIPTION
    Fetches a file in the PATHs and displays its real path.
 
  USAGE: $ ${BASH_SOURCE[0]} file-name [OPTIONS]

  OPTIONS
    -h|--help : Displays this message.
      
    
EOFMAN
}

# -------------------
# Parse parameters
# -------------------
M_INPUTS=()  # many inputs for one option.
args=() # The arguments
while [ $# -ge 1 ]
do
    case "$1" in
        --debug)
          DBG=1
          ;;

        -h|--help)
          man && exit
          ;;

	--dotests)
	  _dotests
	  exit $?
	  ;;

	-*)
	  errexit "Unrecognized option \"$1\"."
	  ;;

        *)
	  args+=("$1")
          shift
          ;;
    esac
    shift
done
set -euf
source editor.lib

## Check file
_file="${args[0]}"
[ "$(type -t "$_file")" = "file" ] \
 || errexit "\"$_file\" is not a command file."

verbecho cmd: $ realpath $(type -p "$_file")
realpath $(type -p "$_file")
