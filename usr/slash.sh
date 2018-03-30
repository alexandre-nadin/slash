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
source sourcesh.lib

slash::safesource() {
  :
}

# Allow permanent aliases
shopt -s expand_aliases

# --------------
# Requirements
# --------------
GREP_EXT_OPTION_PATTERN='-E, --extended-regexp'

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
}

test_requirements \
&& set_slash_grep \
|| return 1


# ----------
#  Library
# ----------
## Function's Regular Expressions
FUNC_REGEX_KEYWORD='\s*(function){0,1}\s*'
FUNC_REGEX_NAME='[^\s]*'
FUNC_REGEX_PARENTHESIS='\s*\(\)\s*'
FUNC_REGEX_BLOC_OPEN='\s*\{\s*'
FUNC_REGEX_BLOC_CLOSE='^\s*\}\s*$'
FUNC_REGEX_DECLARATION="^${FUNC_REGEX_KEYWORD}${FUNC_REGEX_NAME}${FUNC_REGEX_PARENTHESIS}${FUNC_REGEX_BLOC_OPEN}$"

slash__DECORATOR_LIMIT='}'
slash__DECORATOR_LIMIT_REGEX="^\s*${slash__DECORATOR_LIMIT}\s*$"

#
#  Because we need to read directly the template function declaration right
# after the deecorator due to the (ba)sh language, I am forced to use aliases.
#
#  In order to successfully have the new functions' declarations at the currenti
# scope, the 'function-declaring' them (slash::defun) SHOULD NOT be piped. 
#
#  In order not to interprete variables in the template function 'funtemp',
# aliases should not be double-quoted. Double-quoting 'funtemp' inside the alias
# is fine though.
#
alias stdin_or_readfun="io_existing_stdin || readfun"
alias read_funtemp_stdin="funtemp=\$(io_existing_stdin)"
alias read_funtemp_read="read -d '' funtemp <<'${slash__DECORATOR_LIMIT}'"
alias read_funtemp='read_funtemp_stdin || read_funtemp_read'
alias @slash-defun='read_funtemp; slash::defun <<< "$funtemp"' 

alias @slash-greet='read_funtemp; slash::defun <<< "$(slash::greet <<< "$funtemp")"' 
slash::greet() {
  #
  # Takes a template function in input and prepands a greeting line to its
  # recipe.
  #
  local _fun_template _fun_name _fun_recipe _fun_new
  _fun_template="${1:-$(io_existing_stdin)}"
  _fun_name=$(slash::func_name "$_fun_template")
  _fun_recipe=$(slash::func_recipe "$_fun_template")
  cat << eol
    ${_fun_name}() {
    echo "Greetings!"
    ${_fun_recipe}
  }
eol
}

slash::defun() {
  #
  # Takes a template function in input and declares it.
  #
  local _fun_template _fun_name _fun_recipe _fun_new
  _fun_template="${1:-$(io_existing_stdin)}"
  _fun_name=$(slash::func_name "$_fun_template")
  _fun_recipe=$(slash::func_recipe "$_fun_template")
  _fun_new=$(cat << eol
    ${_fun_name}() {
    ${_fun_recipe}
  }
eol
)
  eval "${_fun_new}"
} 

slash::func_recipe() {
  #
  # Retrieves the recipe of the given function declaration
  #
  slash::is_func_declaration "$1" \
  && tail -n +2 <<< "$1" \
   | sed -r " 
       ## Remove empty lines
       /^\s*$/d ;
       ## Remove function's closing block curly bracket if any
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
       ## Remove function keyword
       s|^${FUNC_REGEX_KEYWORD}||g ;
       ## Remove function's open block curly bracket
       s|${FUNC_REGEX_BLOC_OPEN}$||g ;
       ## Remove function's parenthesis
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

set +euf +o pipefail
