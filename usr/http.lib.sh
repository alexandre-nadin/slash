#!/usr/bin/env bash
source functions.lib
source functions.lib
source number.sh

HTTP_TYPES=(\
  SUCCESSFUL 
  INFORMATIONAL
  SUCCESSFUL
  REDIRECTION
  CLIENT_ERROR
  SERVER_ERROR
)

## http types ranges. Syntax: HTTP_TYPE_<TYPE>=(FROM TO)
HTTP_TYPE_INFORMATIONAL=(100 199)
HTTP_TYPE_SUCCESSFUL=(200 299)
HTTP_TYPE_REDIRECTION=(300 399)
HTTP_TYPE_CLIENT_ERROR=(400 499)
HTTP_TYPE_SERVER_ERROR=(500 599)

function _declare_is_functions() {
  #
  # Declares http_is_TYPE functions.
  #
  for _htype in "${HTTP_TYPES[@]}"; do
    eval_func_str "$(_get_is_function_str $_htype)"
  done
}

function _get_is_function_str() {
  #
  # Gets string for defining the is function.
  #
  local htype="$1"
  cat << EOCAT
function.public http_is_type_${htype}() {
  #
  # Checks http code is of type '${htype}'.
  #
  int_is_in_range "\$1" \${HTTP_TYPE_${htype}[@]} \
   && return 0 \
   || return 1
}
EOCAT
}

function http_which_type() {
  #
  # Gets the http type from specified code number.
  #
  local input_nb="$1"
  local http_type_range
  for htype in "${HTTP_TYPES[@]}"; do 
    http_is_type_${htype} "$input_nb" \
     && echo "$htype" \
     && return 0
  done
  return 1
}

## Automatic declarations.
_declare_is_functions
