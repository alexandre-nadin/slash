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
source io.lib
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
  #
  # slash uses perl regex
  #
  alias sgrep='command grep -P'
  alias sogrep='command grep -oP'
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
FUNC_REGEX_KEYWORD='\s*(function){0,1}\s*'
FUNC_REGEX_NAME='[^\s]*'
FUNC_REGEX_PARENTHESIS='\s*\(\)\s*'
FUNC_REGEX_BLOC_OPEN='\s*\{\s*'
FUNC_REGEX_BLOC_CLOSE='^\s*\}\s*$'
FUNC_REGEX_DECLARATION="^${FUNC_REGEX_KEYWORD}${FUNC_REGEX_NAME}${FUNC_REGEX_PARENTHESIS}${FUNC_REGEX_BLOC_OPEN}$"

slash__FUNC_DELIM='}'
slash::func_recipe() {
  #
  # Retrieves the recipe of the given function declaration
  #
  slash::is_func_declaration "$1" \
  && tail -n +2 <<< "$1" \
   | sed -r "
       /^\s*$/d ;
       $ s|${FUNC_REGEX_BLOC_CLOSE}||g ;
     "
}

test__func_recipe() {
  local _func="slash::func_name"
  [ "$($_func ' function hello () { ')" == 'hello' ] || return 1
  :
} && tsh__add_func test__func_recipe

slash::func_name() {
  #
  # Retrieves the name of the given function declaration
  # Assumes 'is_func_declaration' has been tested before.
  #
  slash::is_func_declaration "$1" \
  && head -n 1 <<< "$1" \
   | sed -r "
       s|^${FUNC_REGEX_KEYWORD}||g ;
       s|${FUNC_REGEX_BLOC_OPEN}$||g ;
       s|${FUNC_REGEX_PARENTHESIS}$||g ;
     "
}

test__func_name() {
  local _func="slash::func_name"
  local _res
  [ "$($_func ' function hello () { ')" == 'hello' ] || return 1
  ! [ "$($_func ' function hello () { ')" == 'hello ' ] || return 2
  ! [ "$($_func '  hello () { ')" == 'hello ' ] || return 3

  local _f=$(cat <<eol

    function tre-_llo12 () {
     unction whatever the show() 9)())*IOH {}{ {
      echo one
      echo two
    }
eol
          )
  _res=$($_func "$_f")
  ! [ "$_res" == 'tre-_llo12' ] || return 4

  _res=$($_func "$(sed '/^\s*$/d' <<< "$_f")")
  [ "$_res" == 'tre-_llo12' ] || return 5

} && tsh__add_func test__func_name

slash::is_func_declaration() {
  head -n 1 <<< "$1" \
   | sogrep "${FUNC_REGEX_DECLARATION}" &> /dev/null
}

test__is_func_declaration() {
  #
  # SPECIFICATIONS 
  #  Function declaration should be on the first line.
  #  Initial keyword 'function' is optional.
  #  Function name contains all but whitespaces
  #  Function parenthesis are mandatory
  #  Function declaration ends with a curly bracket.
  #
  local _func="slash::is_func_declaration"
  $_func "   function hello () { " || return 1
  $_func " hello() { " || return 2
  ! $_func "  func hello() { " || return 3
  ! $_func "  func hello() " || return 4
  $_func " function -_hle-lo () {  " || return 5
  ! $_func " function -_hle-lo due () {  " || return 6
} && tsh__add_func test__is_func_declaration

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

