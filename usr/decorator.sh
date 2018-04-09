#!/usr/bin/bash
source logging.lib
source testsh.lib 
source io.lib
source variable.lib
source array-ref.lib

# --------------
# Requirements
# --------------
## Allow permanent aliases
shopt -s expand_aliases

GREP_EXT_OPTION_PATTERN='-E, --extended-regexp'

function set_grep() {
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
&& set_grep \
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

DECORATOR_LIMIT='}'
DECORATOR_LIMIT_REGEX="^\s*${DECORATOR_LIMIT}\s*$"

#
#  Because we need to read directly the template function declaration right
# after the deecorator due to the (ba)sh language, I am forced to use aliases.
#
#  In order to successfully have the new functions' declarations at the currenti
# scope, the 'function-declaring' them (defun) SHOULD NOT be piped. 
#
#  In order not to interprete variables in the template function 'funtemp',
# aliases should not be double-quoted. Double-quoting 'funtemp' inside the alias
# is fine though.
#
alias stdin_or_readfun="io_existing_stdin || readfun"
alias read_funtemp_stdin="funtemp=\$(io_existing_stdin)"
alias read_funtemp_read="read -d '' funtemp <<'${DECORATOR_LIMIT}'"
alias read_funtemp='read_funtemp_stdin || read_funtemp_read'

defun() {
  #
  # Takes a function declaration in input and declares it.
  #
  local _fun_declaration=${1:-$(io_existing_stdin)}
  is_func_declaration "$_fun_declaration"      || return 1
 
  eval "$_fun_declaration"                    || return 2 
}

#defun() {
#  #
#  # Takes a template function in input and declares it.
#  #
#  local _fun_template _fun_name _fun_recipe _fun_new
#  _fun_template="${1:-$(io_existing_stdin)}"
#  _fun_name=$(func_name "$_fun_template") || return 1
#  _fun_recipe=$(func_recipe "$_fun_template") || return 2
#  defun_name_recipe "$_fun_name" "$_fun_recipe" || return 3
#} 

defun_name_recipe() {
  #
  # Declares a function from a name and a recipe given as input.
  #
  local _fun_new=$(build_name_recipe_declaration "$@") || return 1
  defun "$_fun_new" || return 2
}

build_name_recipe_declaration() {
  #
  # Takes a function name and its recipe.
  # Outputs the function's declaration string.
  #
  [ $# -eq 2 ] || return 1
  cat << eol 
    ${1}() {
      ${2}
    }
eol
}

func_recipe() {
  #
  # Retrieves the recipe of the given function declaration.
  #
  local _func_declaration="${1:-io_existing_stdin}"
  is_func_declaration "$_func_declaration" \
  && tail -n +2 <<< "$_func_declaration" \
   | sed -r " 
       ## Remove empty lines
       /^\s*$/d ;
       ## Remove function's closing block curly bracket if any
       $ s|${FUNC_REGEX_BLOC_CLOSE}||g ;
     "
}

test__func_recipe() {
  #local _func="func_name"
  #[ "$($_func ' function hello () { ')" == 'hello' ] || return 1
  :
} && tsh__add_func test__func_recipe

func_name() {
  #
  # Retrieves the name of the given function declaration.
  #
  local _func_declaration="${1:-io_existing_stdin}"
  is_func_declaration "$_func_declaration" \
  && head -n 1 <<< "$_func_declaration" \
   | sed -r "
       ## Remove function keyword
       s|^${FUNC_REGEX_KEYWORD}||g ;
       ## Remove function's opening block curly bracket
       s|${FUNC_REGEX_BLOC_OPEN}$||g ;
       ## Remove function's parenthesis
       s|${FUNC_REGEX_PARENTHESIS}$||g ;
     "
}

test__func_name() {
  local _func="func_name"
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

is_func_declaration() {
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
  local _func="is_func_declaration"
  $_func "   function hello () { " || return 1
  $_func " hello() { " || return 2
  ! $_func "  func hello() { " || return 3
  ! $_func "  func hello() " || return 4
  $_func " function -_hle-lo () {  " || return 5
  ! $_func " function -_hle-lo due () {  " || return 6
} && tsh__add_func test__is_func_declaration


# ----------
# Decorate
# ----------
## Reads stdin function that follows.
# Decorates it with the given existing function names following the decorator.
alias @decorate='read_funtemp; decorate "$funtemp"'

decorate() {
  #
  # Takes a function template and function names in input.
  # Declares the template function and recursively decorates it with each
  # successive function name. Each decorating functon name should exist.
  # 
  # Expects at least one decorator.
  #
  # The inner decorable function is declared and its name is exported as 
  # '_func_decorable'. This variable shall then be used in the decorating
  # function. This variable is cruial for decorating functions and is to be 
  # used as is in the decorator function's recipe. As such, programmer should
  # pay attention not to overwrite them (variable assignemnt, unset, local, etc).
  #
  # Two other variables, '_func_decorated' and '_func_decorator', are exported
  # too for information purpose.
  #
  #
  echo -e "\n[$FUNCNAME]"
  ## Declare local variables
  local _vars=(\
    _decorable_template
    _decorable_name
    _decorable_recipe 
    _decorable_declaration
    _decorated_name 
    _decorable_recipe
    _decorated_name
    _decorated_declaration
    _decorator_names
    _decorator_name)
  local ${_vars[@]}
  _decorable_template="$1"               && shift               || return 1
  _decorable_name=$(func_name "$_decorable_template")           || return 2
  _decorable_recipe=$(func_recipe "$_decorable_template")       || return 3
  _decorated_name="$_decorable_name"
  _decorator_names=("$@")

  ## If no decorator, don't declare anything and return error.
  [ ${#_decorator_names[@]} -gt 0 ]                             || return 4
  
  ## Take last decorator
  _decorator_name="${_decorator_names[$(( ${#_decorator_names[@]} - 1  ))]}"
  arrr_pop _decorator_names &> /dev/null

  ## The decorator function should already have been declared
  declare -f "$_decorator_name" &> /dev/null                    || return 5

  ## Redefine the inner decorable function that will be used by the decorator
  _decorable_name=$(build_decorable_function_name \
    "${_decorable_name}" \
    "${_decorator_name}")                                       || return 6

  ## Declare the inner decorable function if not already exists
  _decorable_declaration=$(build_name_recipe_declaration \
    "${_decorable_name}" \
    "${_decorable_recipe}")                                     || return 7

  [ declare -f "$_decorable_name" &> /dev/null ] \
  || defun_name_recipe \
      "${_decorable_name}" \
      "${_decorable_recipe}"                                    || return 8

  ## Declare the new decorated function 
  _decorated_declaration=$(build_name_recipe_declaration \
    "${_decorated_name}" \
    "$(cat << eol
      (
      ## Export inner function names
      export _func_decorable="${_decorable_name}"
      export _func_decorator="${_decorator_name}"
      export _func_decorated="${_decorated_name}"

      # Call decorator
      ${_decorator_name} "\$@"
      )
eol
    )" \
  )                                                             || return 9

  defun "$_decorated_declaration"                               || return 10

  ## Decorate recursively
  decorate "$_decorated_declaration" "${_decorator_names[@]}"  || :
}

test__decorateX() {
  ## Declare f0 as a decorator.
  #shopt -s expand_aliases
  #type -a @decorator
  f0() {
    local _ret _res
    #_res=$("${_func_decorated}" "$@")
    #_ret=$?
    echo "'${_func_decorated}' @ '${FUNCNAME}' -> '${_func_decorable}'"
  } || return 1

  ## Declare and decorate f1 with f0
  @decorate && return 2
  f1() {
    return 71
}

  @decorate f0 || return 3
  f2() { 
    return 72
}

  #local _decl=$(cat << eol
  #f3() {
  #  return 73
#}
#eol
#)

#  echo "$_decl" | @decorateX || return 4

  

} && tsh__add_func test__decorateX


test__decorate() {
  ## Declare f0 as a decorator.
  #shopt -s expand_aliases
  #type -a @decorator
  @decorator || return 1
  f0() {
    local _ret _res
    _res=$("${_func_decorable}" "$@")
    _ret=$?
    echo "'${FUNCNAME}' @ '${_func_decorable}' -> '_'${FUNCNAME}@${_func_decorable}'"
}
  alias @f0 &> /dev/null || return 2

  ## Declare and decorate f1 with f0
  eval "@f0 || return 3
  f1() { 
    return 7
}"


} && tsh__add_func test__decorate


# ----------
# DecorateX
# ----------
build_decorable_function_name() {  
  [ $# -eq 2 ] || return 1               
  printf "${1}@${2}\n"                   
}                                        

set +euf +o pipefail
