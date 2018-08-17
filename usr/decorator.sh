#!/usr/bin/bash
source source.sh
source::unique logging.lib
source::unique io.lib
source::unique variable.lib
source::unique array.sh
source::unique grep.sh

# --------------
# Requirements
# --------------
## Allow permanent aliases
shopt expand_aliases &> /dev/null || shopt -s expand_aliases

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
&& set_grep                                                     || return 1


# ----------
#  Library
# ----------
## Function's Regular Expressions
FUNC_REGEX_KEYWORD='\s*(function){0,1}\s*'
FUNC_REGEX_NAME='\s*[^\s]*\s*'
FUNC_REGEX_PARENTHESIS='\s*\(\s*\)\s*'
FUNC_REGEX_BLOC_OPEN='\s*\{\s*'
FUNC_REGEX_BLOC_CLOSE='^\s*\}\s*$'
FUNC_REGEX_DECLARATION="^${FUNC_REGEX_KEYWORD}${FUNC_REGEX_NAME}${FUNC_REGEX_PARENTHESIS}${FUNC_REGEX_BLOC_OPEN}$"

DECORATOR_LIMIT='}'
DECORATOR_LIMIT_REGEX="^\s*${DECORATOR_LIMIT}\s*$"

#
#  Because we need to read directly the template function declaration right
# after the decorator due to the (bash) language, I am forced to use aliases here.
#
#  In order to successfully have the new functions' declarations at the current
# scope, the 'function-declaring' them (defun) SHOULD NOT be piped. 
#
#  In order not to interprete variables in the template function '$FUNTEMP',
# aliases should not be double-quoted. Double-quoting '$FUNTEMP' inside the alias
# is fine though.
#
FUNTEMP=funtemp
alias read_funtemp_stdin="${FUNTEMP}=\$(io_existing_stdin)"
alias read_funtemp_read="read -d '' ${FUNTEMP} <<'${DECORATOR_LIMIT}'"
alias read_funtemp='read_funtemp_stdin || read_funtemp_read || :'

# ------------------
# Function parsers
# ------------------
is_func_declaration() {
  head -n 1 <<< "$1" \
   | sogrep "${FUNC_REGEX_DECLARATION}" &> /dev/null
}

func_declaration() {
  #
  # Loops over the function body until it finds a function declaration.
  # If not returns 1.
  # Ignores empty lines.
  # 
  local _func_body="${1:-$(io_existing_stdin)}"
  while read _line; do
    is_func_declaration "$_line" \
     && pecho "$_line" \
     && return 0 \
     || continue
  done <<< "$_func_body"
  return 1
}

func_name() {
  #
  # Retrieves the name of the given function body.
  #
  local _func_declaration
  _func_declaration=$(func_declaration "${1:-$(io_existing_stdin)}") \
                                                                || return 1
  sed -r "
    ## Remove function keyword
    s|^${FUNC_REGEX_KEYWORD}||g ;
    ## Remove function's opening block curly bracket
    s|${FUNC_REGEX_BLOC_OPEN}$||g ;
    ## Remove function's parenthesis
    s|${FUNC_REGEX_PARENTHESIS}$||g ;
  " <<< "$_func_declaration"                                    || return 2
}

func_recipe() {
  #
  # Retrieves the recipe of the given function declaration.
  #
  local _func_body _func_declaration _decla_lineNb
  _func_body="${1:-$(io_existing_stdin)}"
  _func_declaration=$(func_declaration "$_func_body")           || return 1
  _decla_lineNb=$(( $(grep__lineNumber "$_func_declaration" <<< "$_func_body") + 1))
  tail -n +$_decla_lineNb \
    <<< "$_func_body" \
    | sed -r "
       ## Remove empty lines
       /^\s*$/d ;
       ## Remove function's closing block curly bracket if any
       $ s|${FUNC_REGEX_BLOC_CLOSE}||g ;
     "
}

func_get_decorators() {
  :
}

func_type() {
  :
}


# ----------------------
# Function definitions
# ----------------------
defun() {
  #
  # Takes a function declaration in input and declares it.
  #
  local _fun_declaration=${1:-$(io_existing_stdin)}
  is_func_declaration "$_fun_declaration"                       || return 1
  eval "$_fun_declaration"                                      || return 2 
}

defun_name_recipe() {
  #
  # Declares a function from a name and a recipe given as input.
  #
  local _fun_new=$(build_name_recipe_declaration "$@")          || return 1
  defun "$_fun_new"                                             || return 2
}

build_name_recipe_declaration() {
  #
  # Takes a function name and its recipe.
  # Outputs the function's declaration string.
  #
  [ $# -eq 2 ]                                                  || return 1
  cat << eol 
${1}() {
  ${2}
}
eol
}


# ----------
# Decorate
# ----------
## Reads stdin function that follows.
# Decorates it with the given existing function names following the decorator.
alias @decorate='read_funtemp && decorate "${!FUNTEMP}"'

function is_alias() {
  alias "$1" &> /dev/null 
}

function is_function() {
  declare -f "$1" &> /dev/null
}

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

  # For now we can apply a decorator only once
  _decorator_names=($(arrr_set $@))

  ## If no decorator, don't declare anything and return error.
  [ ${#_decorator_names[@]} -gt 0 ]                             || return 4
  
  ## Take last decorator
  _decorator_name=$(arrr_pop _decorator_names)                  || return 5
  arrr_pop _decorator_names &> /dev/null                        || return 6
  
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

  ## Decorate recursively if some decorators left
  [ ${#_decorator_names[@]} -gt 0 ]                             || return 0
  decorate "$_decorated_declaration" "${_decorator_names[@]}"   || :
}

build_decorable_function_name() {  
  [ $# -eq 2 ]                                                  || return 1               
  printf "${1}@${2}\n"                   
}                                        
