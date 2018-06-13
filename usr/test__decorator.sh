#!/usr/bin/env bash
source decorator.sh

test__build_name_recipe_declaration() {
  local _func="build_name_recipe_declaration" _test_string
  _res=$($_func \
     "hello" \
     "echo 'Hello world!'"
  )                                                             || return 1
  _test_string=$(cat << eol
hello() {
  echo 'Hello world!'
}
eol
)

  [ "$_test_string" == "$_res" ]                                || return 2
  ! $_func "hello"                                              || return 3
  ! $_func "hello" "param1" "param2"                            || return 4
   
} && tsh__add_func test__build_name_recipe_declaration

test__func_recipe() {
  local _func="func_recipe" _test_func_declaration
 
  # ---
  # Normal declaration
  _test_func_declaration=$(build_name_recipe_declaration \
    "Hello" \
    "echo 'Hello world!'")                                      || return 1
  _func_recipe=$($_func "$_test_func_declaration")
  [ "$_func_recipe" == "  echo 'Hello world!'" ]                || return 2

  # ---
  ! build_name_recipe_declaration \
    "" \
    "Hello" \
    "echo 'Hello world!'" \
     &> /dev/null                                               || return 3

  # --
  # Declare first empty line
  _test_func_declaration=$(build_name_recipe_declaration \
    "$(cat << eol

Hello
eol
)" \
    "echo 'Hello world2"
   )                                                            || return 4

  # Test first line
  ! $_func "$_test_func_declaration"                            || return 5  
  
} && tsh__add_func test__func_recipe

test__func_name() {
  local _func="func_name"
  local _res
  [ "$($_func ' function hello () { ')" == 'hello' ]            || return 1
  ! [ "$($_func ' function hello () { ')" == 'hello ' ]         || return 2
  ! [ "$($_func '  hello () { ')" == 'hello ' ]                 || return 3

  local _f=$(cat <<eol

    function tre-_llo12 () {
     unction whatever the show() 9)())*IOH {}{ {
      echo one
      echo two
    }
eol
          )
  _res=$($_func "$_f")
  ! [ "$_res" == 'tre-_llo12' ]                                 || return 4

  _res=$($_func "$(sed '/^\s*$/d' <<< "$_f")")
  [ "$_res" == 'tre-_llo12' ]                                   || return 5

} && tsh__add_func test__func_name

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
  $_func "   function hello () { "                              || return 1
  $_func " hello() { "                                          || return 2
  ! $_func "  func hello() { "                                  || return 3
  ! $_func "  func hello() "                                    || return 4
  $_func " function -_hle-lo () {  "                            || return 5
  ! $_func " function -_hle-lo due () {  "                      || return 6
} && tsh__add_func test__is_func_declaration

test__decorate() {
  # ----------------
  # Positive tests
  # ----------------
  tag-div() {
    local _res _ret
    _res=$("$_func_decorable" "$@") && _ret=$? || _ret=$?
    printf "<div>${_res}</div>\n"
    return $_ret
  }
 
  tag-p() {
    local _res _ret
    _res=$("$_func_decorable" "$@") && _ret=$? || _ret=$?
    printf "<p>${_res}</p>\n"
    return $_ret
  }

  tag-strong() {
    local _res _ret
    _res=$("$_func_decorable" "$@") && _ret=$? || _ret=$?
    printf "<strong>${_res}</strong>\n"
    return ${_ret:-$?}
  }

  @decorate \
  tag-div \
  tag-p tag-strong                                              || return 3
  hello() {
    echo "Hello user"
}

  is_function hello                                             || return 4
  is_function hello@tag-strong                                  || return 5
  is_function hello@tag-p                                       || return 6
  is_function hello@tag-div                                     || return 7
  [ "$(hello)" == "<div><p><strong>Hello user</strong></p></div>" ] \
                                                                || return 8
  unset -f hello hello@tag-strong hello@tag-p hello@tag-div

  # ----------------
  # Negative tests
  # ----------------
  @decorate                                                     && return 1 || :
  hello_no_decorator() {
    echo "hello $USER"
}
  ! is_function hello_no_decorator                              || return 2 

  # ----- 
  wrong_decorable_return() {
    local _res _ret
    _res=$("$_func_decorable" "$@") || _ret=$?
    printf "<wrong>${_res}</wrong>\n"
    return ${_ret:-$?}
  }

  @decorate wrong_decorable_return
  hello_wdr() {
    echo "Hello"
    return 1
}

  is_function hello_wdr                                         || return 9
  is_function hello_wdr@wrong_decorable_return                  || return 10
  hello_wdr &> /dev/null
  [ $? -eq 1 ]                                                  || return 11
 
  # ----- 
  wrong_decorable_name() {
    local _res _ret
    _res=$("$_non_existent_func_decorable" "$@") || _ret=$?
    printf "<wrong>${_res}</wrong>\n"
    return ${_ret:-$?}
  }

  @decorate wrong_decorable_name 
  hello_wdn() {
    echo "Hello"
}

  ! hello_wdn &> /dev/null                                      || return 12

  # ----
  wrong_decorator_cmd() {
    local _res _ret
    _res=$("$_func_decorable" "$@") || _ret=$?
    wrong_deco_cmd "<wrong_deco_cmd>${_res}</wrong_deco_cmd>\n" \
      2> /dev/null
    return ${_ret:-$?}
  }

  @decorate wrong_decorator_cmd
  hello_wdc() {
    echo "Hello"
}
  [ "$(hello_wdc)" == "" ]                                      || return 13
  hello_wdc &> /dev/null; [ $? -eq 127 ]                        || return 14

} && tsh__add_func test__decorate

test__build_decorable_function_name() {
  local _func="build_decorable_function_name"
  ! $($_func one)                                               || return 1
  ! $($_func one two three)                                     || return 2
  [ "$($_func one two)" == "one@two" ]                          || return 3
  
} && tsh__add_func test__build_decorable_function_name