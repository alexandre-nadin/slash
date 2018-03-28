#!/usr/bin/env bash
slash::source() {
  #
  # Saves the current shell set options before sourcing the given file.
  # Restores them afterwords.
  #
  local _setoptions=$(set +o | sed 's/$/;/g')
  source "$1"
  eval "$_setoptions"
}

source logging.lib
source testsh.lib 
slash::source sourcesh.lib

slash::testlib() {
  local _lib="$1"
  source "$_lib"
  tsh__test_funcs 
}

slash::safesource() {
  :
}


# --------------
# Requirements
# --------------
GREP_EXT_OPTION_PATTERN='-E, --extended-regexp'
shopt -s expand_aliases

function set_slash_grep() {
  alias sgrep='command grep -oP'
}
function test_requirements() {
  ## Gnu Grep
  type -af egrep &> /dev/null \
  || {
      errecho "Cannot find egrep"
      return 1
     }

  ## Grep Extended Regex
  grep --help \
   | grep -- "$GREP_EXT_OPTION_PATTERN" \
   &> /dev/null \
  || {
       errecho "This version of Grep doesn't have extended regex option ($GREP_EXT_OPTION_PATTERN)."
       return 1
     }
} #&& test_requirements || return 1

test_requirements \
&& set_slash_grep \
|| return 1

# ----------
#  Library
# ----------
FUNC_REGEX_PREFIX='^\s*(function){0,1}\s*'
FUNC_REGEX_NAME='[^\s]*'
FUNC_REGEX_DECLARATION="${FUNC_REGEX_NAME}"'\s*\(\)'
FUNC_REGEX_SUFFIX='\s*\{\s*$'
FUNC_REGEX="${FUNC_REGEX_PREFIX}${FUNC_REGEX_DECLARATION}${FUNC_REGEX_SUFFIX}"

slash__FUNC_DELIM='}'
slash::func_recipe() {
  #
  # Retrieves the recipe of the given function declaration
  #
  printf "$1"
}

slash::is_func_declaration() {
  head -n 1 <<< "$1" | sgrep "${FUNC_REGEX}" &> /dev/null
}

t_is_func_declaration() {
  local _func="slash::is_func_declaration"
  $_func " function hello () { " || return 1
  $_func " hello() { " || return 2
  ! $_func "  func hello() { " || return 3
  ! $_func "  func hello() " || return 4
  $_func " function -_hle-lo () {  " || return 5
  ! $_func " function -_hle-lo due () {  " || return 6
} && tsh__add_func t_is_func_declaration

slash::func_name() {
  #
  # Retrieves the name of the given function declaration
  #
  echo -e "$@" \
   | grep "$FUNC_REGEX"
   #| sed 's/^[[:space:]]*function[[:space:]]*//'
  #grep "^[[:space:]]*(function)?[[:space:]]*[[:word:]]*()[[:space:]]*$" <<< "$1"
}

source io.lib
slash::defun() {
  echo "[$FUNCNAME]"
  local _input=$(io_existing_stdin)
  echo -e "\n_input: $_input ($(echo -e $_input | wc -l))"
  

  local _funcname=$(slash::func_name "$_input")
  echo -e "\n_funcname: '$_funcname'"
  ## Function recipe
  local _recipe=$(slash::func_recipe "$_input")
  echo -e "\n_recipe: '$_recipe'"
} && alias @slash-func="cat << '$slash__FUNC_DELIM' | slash::defun"

