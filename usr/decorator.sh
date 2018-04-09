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
  # Takes a template function in input and declares it.
  #
  local _fun_template _fun_name _fun_recipe _fun_new
  _fun_template="${1:-$(io_existing_stdin)}"
  _fun_name=$(func_name "$_fun_template") || return 1
  _fun_recipe=$(func_recipe "$_fun_template") || return 2
  defun_name_recipe "$_fun_name" "$_fun_recipe" || return 3
} 

defun_name_recipe() {
  #
  # Declares a function from a name and a recipe given as input.
  #
  local _fun_new=$(build_name_recipe "$@") || return 1
  eval "${_fun_new}" || return 2
}

build_name_recipe() {
  [ $# -eq 2 ] || return 1
  cat << eol 
    ${1}() {
      ${2}
    }
eol
}

func_recipe() {
  #
  # Retrieves the recipe of the given function declaration
  #
  is_func_declaration "$1" \
  && tail -n +2 <<< "$1" \
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
  # Retrieves the name of the given function declaration
  # Assumes 'is_func_declaration' has been tested before.
  #
  is_func_declaration "$1" \
  && head -n 1 <<< "$1" \
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


# ------------------
# Define decorator
# ------------------
alias @decorator='read_funtemp; defcorator <<< "$funtemp"'
function defcorator() {
  #
  # Takes a template function in input and declares it.
  # Creates a decorator alias referencing it.
  #
  local _fun_template _fun_name _fun_recipe _fun_new

  ## Declare function from template
  _fun_template="${1:-$(io_existing_stdin)}" || return 1
  defun <<< "$_fun_template" || return 2

  ## Declare alias from function name
  _fun_name=$(func_name "$_fun_template") || return 3
  defalias <<< "$_fun_name" || return 4
} 

test__defcorator() {
  local _res

  #
  @decorator && return 1 || :
  functionn test1() {
  echo "in test1" && return 1
}
  declare -f test1 &> /dev/null && return 2 || :
  alias @test1 &> /dev/null && return 3 || :

  #
  @decorator && return 4 || :
  t test2() {
    echo "test2" && return 2
}
  declare -f test2 &> /dev/null && return 5 || :
  alias @test2 &> /dev/null && return 6 || :

  #
  @decorator || return 7
     function test3() {
    echo "test3" && return 3
}
  declare -f test3 &> /dev/null || return 8
  alias @test3 &> /dev/null || return 9
  [ "$(test3)"  == "test3" ] || return 10
  test3 &> /dev/null; [ $? -eq 3 ] || return 11 
} && tsh__add_func test__defcorator

defalias() {
  #
  # Takes a function name and declares an alias-decorator from it.
  #
  local _fun_name _alias_name _alias_declaration
  _fun_name="${1:-$(io_existing_stdin)}" || return 1
  _alias_name=$(gen_alias_name "$_fun_name") || return 2
  _alias_declaration=$(gen_alias_declaration <<< "$_alias_name") || return 3
  #echo eval "$_alias_declaration" || return 4
  eval "$_alias_declaration" || return 4
}

test__defalias() {
  local _func="defalias"
  $_func <<< "hello" || return 1
  alias hello &> /dev/null && return 2
  alias @hello &> /dev/null || return 3
  ! $_func " hello world " || return 4
} && tsh__add_func test__defalias


gen_alias_declaration() {
  local _alias_name _alias_declaration
  _alias_name="${1:-$(io_existing_stdin)}"
  read -d '' _alias_declaration <<eod || :
alias @${_alias_name}='read_funtemp; decorate "\$funtemp" "${_alias_name}"'
eod
  printf "$_alias_declaration\n"
}

test__gen_alias_declaration() {
  local _func="gen_alias_declaration"
  [ "$($_func ' some name ')" == "alias @ some name ='read_funtemp; decorate "'"$funtemp"'" "'" some name "'"'" ] || return 1

  [ "$($_func ' some ' ' name ')" == "alias @ some ='read_funtemp; decorate "'"$funtemp"'" "'" some "'"'" ] || return 2

} && tsh__add_func test__gen_alias_declaration

gen_alias_name() {
  #
  # Formats the input to a suitable alias name.
  #
  local _oldname _newname
  _oldname="${1:-$(io_existing_stdin)}"
  _newname=$(
    sed -r "
      ## Remove multiple word lines
      /\w+\s+\w+/d ;
      ## Remove beginning spaces
      s|^\s*||g ;
      ## Remove trailing spaces
      s|\s*$||g ;
    " <<< "$_oldname"
  )
  printf "$_newname\n"
  [ "${#_newname}" -gt 0 ] \
   || return 1
}

test__gen_alias_name() {
  local _func="gen_alias_name"
  [ "$($_func ' ')" == '' ] || return 1
  [ "$($_func '')" == '' ] || return 1
  [ "$($_func ' ')" == '' ] || return 2
  [ "$($_func ' my-name')" == 'my-name' ] || return 3
  [ "$($_func <<< ' _12some-other_name      ')" == '_12some-other_name' ] || return 4
  [ "$($_func ' some composed names ')" == '' ] || return 5
  [ "$($_func <<< ' some other_+composed names ')" == '' ] || return 6
} && tsh__add_func test__gen_alias_name


# ----------
# Decorate
# ----------
decorate() {
  #
  # Decorates first function with the second given as parameters.
  #
  # $1 is the decorable function template read from stdin. It will be parsed,
  # declared, then decorated with $2.
  #
  # $2 is the decorating function name. It is expected to be already
  # declared thanks to the declaring decorator '@decorator'.
  #  
  # The inner decorable function is declared and its name is exported as '_func_decorable'.
  #
  # The inner decorated function, which is the decorable function that has been
  # decorated with the decorating function, is declared and its name is exported
  # as '_func_decorated'. 
  #
  # Those two exported function names are to be used as is in the decorator
  # function's recipe. As such, programmer should pay attention not overwritting
  # them (variable assignemnt, unset, local, etc).
  #
  local _decorator_name _decorated_name _decorable_name _decorable_recipe 
  #_decorable_name=$(func_name "$1") || return 1
  _decorated_name=$(func_name "$1") || return 1
  _decorable_recipe=$(func_recipe "$1") || return 2

  ## Here the decorator function has already been declared
  _decorator_name="$2"
  declare -f "$_decorator_name" &> /dev/null || return 3

  ## Declare the inner decorable function
  _decorable_name="_${_decorator_name}@${_decorated_name}"
  defun_name_recipe \
    "${_decorable_name}" \
    "${_decorable_recipe}"


  ## Declare the new decorated function 
  defun_name_recipe \
    "${_decorated_name}" \
    "$(cat << eol
      (
      ## Export inner function names
      export _func_decorated="${_decorated_name}"
      export _func_decorable="${_decorable_name}"
      export _func_decorator="${_decorator_name}"

      # Call decorator
      ${_decorator_name} "\$@"
      )
eol
    )"

}

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
## Reads stdin function that follows.
# Decorates it with the given existing function names following the decorator.
alias @decorateX='read_funtemp; decorateX "$funtemp"'

decorateX() {
  #
  # f0() { echo "in f0, using $_func_decorated (f2@f0)"; }
  #
  # @decorateX f0
  # f1() { echo original f1; }
  #
  # f0 is already declared
  # f1 is declared as the decorated function:
  #
  # 
  # f2@f1 is declared as the decorable function
  #f1 -> f1      decorator -> func_decorator
  #@decorateX f1
  #f2() -> f2()  decorable -> func_decorable
  #        f1@f2 decorated -> func_decorated
  echo -e "\n[$FUNCNAME]"
  ## Declare vars
  local _decorable_template _decorated_name _decorable_recipe \
        _decorated_name _decorable_name _decorable_recipe \
        _decorator_names _decorator_name \
        _decorable_declaration _decorated_declaration
  _decorable_template="$1"               && shift           || return 1
  _decorable_name=$(func_name "$_decorable_template")       || return 2
  _decorable_recipe=$(func_recipe "$_decorable_template")   || return 3
  _decorated_name="$_decorable_name"
  _decorator_names=("$@")

  ## If no decorator, don't declare anything and return error.
  [ ${#_decorator_names[@]} -gt 0 ]                         || return 4
  
  ## Take last decorator
  #_decorator_name="${_decorator_names[0]}"
  echo "decorators: '${_decorator_names[@]}'."
  _decorator_name="${_decorator_names[$(( ${#_decorator_names[@]} - 1  ))]}"
  arrr_pop _decorator_names
  echo "decorators: '${_decorator_names[@]}'."
  echo "decorating '$_decorable_name' with '$_decorator_name' (decorators left: '${_decorator_names[@]}') ..."

  ## The decorator function should already have been declared
  declare -f "$_decorator_name" &> /dev/null                || return 5

  ## Redefine the inner decorable function name that will be used by the
  # decorator
  _decorable_name="${_decorable_name}@${_decorator_name}"
  echo "_decorable_name: '$_decorable_name'"

  ## Declare the inner decorable function if not already exists
  _decorable_declaration=$(build_name_recipe \
    "${_decorable_name}" \
    "${_decorable_recipe}") \
  || return 6

  echo "_decorable_declaration: '$_decorable_declaration'"
  [ declare -f "$_decorable_name" &> /dev/null ] \
  || defun_name_recipe \
      "${_decorable_name}" \
      "${_decorable_recipe}" \
  || return 7


  ## Declare the new decorated function 
#  defun_name_recipe \
#    "${_decorated_name}" \
#    "$(cat << eol
#      (
#      ## Export inner function names
#      export _func_decorable="${_decorable_name}"
#      export _func_decorator="${_decorator_name}"
#      export _func_decorated="${_decorated_name}"
#
#      # Call decorator
#      ${_decorator_name} "\$@"
#      )
#eol
#    )" \
#    || return 8
  _decorated_declaration=$(build_name_recipe \
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
  ) \
  || return 8

  defun "$_decorated_declaration" \
  || return 9

  ## Decorate recursively
  decorateX "$_decorated_declaration" "${_decorator_names[@]}"
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
  @decorateX && return 2
  f1() {
    return 71
}

  @decorateX f0 || return 3
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


set +euf +o pipefail


decorateY() {
  #
  # Takes a function template and decorates it with the one given function name.
  #
  :
}





