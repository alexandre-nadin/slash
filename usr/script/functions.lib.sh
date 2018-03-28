#!/usr/bin/env sh
source logging.lib
source variable.lib

# ------------------------------
# Map functions to file streams
# ------------------------------
function functions::map_read_files() {
  #
  # Maps the given function to each line of the given file.
  # If no file are given, reads from the standard input.
  # Careful to use functions in same shell (block declared with '{}' instead 
  # of '()') as opening new sub-shells for each input has a cost in time.
  #   Ex:
  #     yes: sameshell() { echo "This is done is the same shell ($BASHPID)"; }
  #     no: subshell() ( echo "This is done in a subshell ($BASHPID); }
  #
  local _func _files
  _func="$1" && shift
  _files=(${@:-/dev/stdin})
  for _file in "${_files[@]}"; do
    while IFS='' read -r _line || [[ -n "$_line" ]]; do
      $_func "$_line"
    done < "$_file"
  done
}


# --------------------------
# Evaluate function strings
# --------------------------
function eval_func_str() {
  #
  # Formats the given string and evaluates it to declare it as a function. 
  # Removes comments; Puts semicolons at the end of each line.
  #
  local _str=$(
    echo "$@" \
      | grep -v -e "^[[:space:]]*#" <<< "$@" \
      | sed 's|\([{}]\)[[:space:]]*#.*$|\1|' \
      | sed 's|;[[:space:]]*$||' \
      | sed 's|$|;|' \
      | sed 's|{[[:space:]]*;|{|'
    )
  eval "$_str"
}

function get_funcs_ls_str() {
  #
  # Generates a string for declaring the function for 
  # for listing a file's function types.
  #
  local _func_type="$1"
  cat << EOCAT
function.public funcs_ls_${_func_type}() { 
  #
  # Looks for ${_func_type} functions of the given file.
  # 
  debugecho "Listing ${_func_type} functions in file \"\$1\"."
  funcs_ls "\$1" ".${_func_type}"
}
EOCAT
}

function func__get_func_recipe() {
  #
  # Outputs the given function name's recipe.
  #
  declare -f "$1" \
   | tail -n +3 \
   | head -n -1
}


# -------------------------
# Declares function types
# aliases and functions
# -------------------------
_function_types=(public private)

function declare_func_types_aliases() {
  #
  # Declares aliases for each type of function given.
  #
  ## We first need to expand aliases to non-interactive shell: 
  shopt -s expand_aliases 
  for _functype in "$@"; do
    alias function.${_functype}='function'
    verbecho "alias function.${_functype}='function'"
  done
}

function declare_func_types_ls_functions() {
  #
  # Declares redundent functions for listing a script's own function types.
  #
  for _func_type in "${_function_types[@]}"; do
    eval_func_str "$(get_funcs_ls_str ${_func_type})"
  done
}

function set_types_declarations() {
  #
  # Declares listing functions and function aliases for 
  # each given type of function.
  #
  declare_func_types_aliases "$@"
  declare_func_types_ls_functions "$@"
}

set_types_declarations "${_function_types[@]}"

# ---------------
# Function types
# ---------------
function.public funcs_ls() {
  #
  # Looks for functions of the given type
  # in the given file.
  #
  local _file="$1" && shift
  local _func_type="${1:-.*}"
  local _pattern_func_identifers="[a-zA-Z0-9_]*"
  local _pattern_func_declaration="^[[:space:]]*function${_func_type}[[:space:]]*${_pattern_func_identifers}[[:space:]]*([[:space:]]*)"
  grep "${_pattern_func_declaration}" "$_file"
}

function.public func_pipe() {
  #
  # Calls a function as pipeable.
  #
  local func="$1" && shift
  while IFS='' read -r line || [[ -n "$line" ]]; do
    $func "$line"
  done
  ## Process parameters if any too.
  [ $# -gt 0 ] \
   && $func "$@" \
   || true
}

# ------------------
return 

## NOT IMPLEMENTED
## Mayb be too complex and not effective.
function.public func_pipeable () {
  #
  # Takes a function as input and redefines it to make it pipable. 
  #
  local func_name="$1" && shift
  type "$func_name" &> /dev/null || return 0
  #local func_content=$(declare -f "$func_name" | tail -n +3 | head -n -1)
  local func_content=$(declare -f "$func_name" | tail -n +2 | sed -e '/^{\|^}/d')
  debugecho "Func content: '\n$func_content\n'"
  function "$func_name" () {
    while ifs='' read -r line || [[ -n "$line" ]]; do
      
    done
  }

}
