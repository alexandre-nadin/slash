#!/usr/bin/env bash

source logging.lib
source datetime.lib
source functions.lib

#verbecho, errecho, infecho, etc.
function _dotests() {
  echo "Running tests..."
  _test_1
  _test_2
  return 7
}

function man() {
cat << EOFMAN
 
  DESCRIPTION
    Lists the functions in the given file.
    Each function should be properly declared with the keyword "function".
    Private/internal functions should be prepended with an underscore "_".
    Comments should be put between the function definition and the actual code.
    By default all functions declared with the 'function' keyword are all listed without their doc.

    Example:
	function PUBLIC_FUNCTION() {
 	  # This is my 
	  # public comment
	  some commands
	}
 	function _PRIVATE_FUNCTION() {
	  #
	  # This is my internal comment
	  some other commands
	 }
 
  USAGE: $ ${BASH_SOURCE[0]} [OPTIONS] FILE

  OPTIONS
    -h|--help : Displays this message.
    --public : Prints public functions only. 
    --private : Print private functions only.
    (-d|--doc : Prints the functions' documentation.)  NOT IMPLEMENTED
      
    
EOFMAN
}

# -------------------
# Parse parameters
# -------------------
M_INPUTS=()  # many inputs for one option.
params=() # The arguments

LS_FUNCTION="funcs_ls"

while [ $# -ge 1 ]
do
    case "$1" in
        --debug)
          DEBUG=true
          ;;

        -h|--help)
          man && exit
          ;;

	-f|--force)
	  _FORCE="$1"
	  ;;

	--public)
	  LS_FUNCTION="funcs_ls_public"
	  ;;

	--private)
	  LS_FUNCTION="funcs_ls_private"
	  ;;

	--dotests)
	  _dotests
	  exit $?
	  ;;

	-*)
	  errexit "Unrecognized option '$1'. Please check the help (-h|--help)."
	  ;;

        *)
	  params+=("$1")
          ;;
    esac
    shift
done


for f in ${params[@]}; do
  debugecho "Listing functions from '$f' with '$LS_FUNCTION'"
  $LS_FUNCTION "$f"
done


## Todo
# Get starting line
# Get ending line of function
# parsing comments
