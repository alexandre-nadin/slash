#!/usr/bin/env bash

source logging.lib
source datetime.lib

function man() {
cat << EOFMAN
 
  DESCRIPTION
    Fetches a file in the PATHs and edits it.
 
  USAGE: $ ${BASH_SOURCE[0]} FILE [.. FILE] [OPTIONS]

  OPTIONS
    -h|--help : Displays this message.
      
    
EOFMAN
}

# -------------------
# Parse parameters
# -------------------
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
          ;;
    esac
    shift
done
set -euf
source editor.lib

## Check file
_files=()
for _file in "${args[@]}"; do
  [ "$(type -t "$_file")" = "file" ] \
   || errexit "\"$_file\" is not a file."
  _files+=($(realpath $(type -p "$_file")))
done

verbecho cmd: $ $EDITOR ${_files[@]}
$EDITOR ${_files[@]}
