#!/usr/bin/env bash
source decorator.sh

test__is_func_declaration() {
  #
  # SPECIFICATIONS 
  #  Function declaration should be on the first line.
  #  Initial keyword 'function' is optional.
  #  Function name can contains all but whitespaces.
  #  Function parenthesis are mandatory.
  #  Function declaration ends with a curly bracket.
  #
  local _func="is_func_declaration"
  $_func "   function hello () { "                              || return 1
  $_func " hello(  ) { "                                        || return 2
  ! $_func "  func hello() { "                                  || return 3
  ! $_func "  func hello() "                                    || return 4
  $_func " function -_hle-lo () {  "                            || return 5
  ! $_func " function -_hle-lo due () {  "                      || return 6
} && tsh__add_func test__is_func_declaration

test__func_declaration() {
  #
  # SPECIFICATIONS 
  #  Function declaration should be on the first line.
  #  Initial keyword 'function' is optional.
  #  Function name can contains all but whitespaces.
  #  Function parenthesis are mandatory.
  #  Function declaration ends with a curly bracket.
  #
  local _func="func_declaration" _ret _res

  ## Correct full declaration
  _res=$( $_func "$(cat << '  eol'

    function hello() {
      echo HIho
      whatever are you?
    }

  eol
  )" ) && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 1
  [ "$_res" == "function hello() {" ]                           || return 2

  ## Correct declaration without keyword
  _res=$( $_func "$(cat << '  eol'

     hello  (  ) { 

      echo HIho

      whatever are you?
    }

  eol
  )" ) && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 3
  [ "$_res" == "hello  (  ) {" ]                                || return 4

  ## Incorrect declaration no opening curly brackets
  _res=$( $_func "$(cat << '  eol'

     hello  (  ) {o

      echo HIho

      whatever are you?
    }

  eol
  )" ) && _ret=$? || _ret=$?
  [ $_ret -gt 0 ]                                               || return 5
  [ "$_res" == "" ]                                             || return 6

} && tsh__add_func test__func_declaration

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
  [ "$_res" == 'tre-_llo12' ]                                   || return 4

  _res=$($_func "$(sed '/^\s*$/d' <<< "$_f")")
  [ "$_res" == 'tre-_llo12' ]                                   || return 5

} && tsh__add_func test__func_name

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
    "echo 'Hello world2'"
   )                                                            || return 4

  # Test first line
  _res=$($_func "$_test_func_declaration") \
   && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 5  
  [ "$_res" == "  echo 'Hello world2'" ]                        || return 6

  # --
  # Function with nonsense recipe: Should pass
  _test_func_declaration=$(cat << eol
function hello () {
Hello wrld! This
  echo is not a valid
 fuction recipe but still passes the test
*}()$&
eol
)
  _res=$($_func "$_test_func_declaration") \
   && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 7
  [ "$_res" == "$(cat << eol
Hello wrld! This
  echo is not a valid
 fuction recipe but still passes the test
*}()$&
eol
                  )" ]                                          || return 8

  # ----
  # Bad function declaration with correct recipe: Shall not pass!!
  _test_func_declaration=$(cat << eol
function hello() {(*
  echo "This recipe is super valid but not the declaration."
}
eol
  )
  _res=$($_func "$_test_func_declaration") \
   && _ret=$? || _ret=$?
  [ $_ret -ne 0 ]                                               || return 9
  [ "$_res" == "" ]
} && tsh__add_func test__func_recipe

test__is_decorator_declaration() {
  local _func="is_decorator_declaration" _res _ret
  ## 
  _res=$( $_func "$(cat << '   eol'
     whatever
     @decorator
   eol
        )"
   ) && _ret=$? || _ret=$?
   [ $_ret -ne 0 ]                                              || return 1
   [ "$_res" == "" ]                                            || return 2
  
  ##
  _res=$( $_func "$(cat << '   eol'
    
     @decorator
   eol
        )"
   ) && _ret=$? || _ret=$?
   [ $_ret -ne 0 ]                                              || return 3
   [ "$_res" == "" ]                                            || return 4

  ##
  _res=$( $_func "$(cat << '   eol'
     @decorator
   eol
        )"
   ) && _ret=$? || _ret=$?
   [ $_ret -eq 0 ]                                              || return 5
   [ "$_res" == "" ]                                            || return 6

  ##
  _res=$( $_func "$(cat << '   eol'
     @decorator one two \
       three
       @anotherDecorator four five
   eol
        )" | xargs
   ) && _ret=$? || _ret=$?
   [ $_ret -eq 0 ]                                              || return 7
   [ "$_res" == "one two three" ]                               || return 8
} && tsh__add_func test__is_decorator_declaration

test__func_decorators() {
  local _func="func_decorators"

  ## No function declaration
  _res=$( $_func "$(cat << '   eol'
       
       @anotherDecorator one two
   eol
        )" | xargs
   ) && _ret=$? || _ret=$?
   [ $_ret -ne 0 ]                                              || return 1
   [ "$_res" == "" ]                                            || return 2

  ## Wrong decorator
  _res=$( $_func "$(cat << '   eol'
      
       wrongDecorator one two 
       @anotherDecorator three four
      function myfunc() {

      }
   eol
        )" | xargs
   ) && _ret=$? || _ret=$?
   [ $_ret -ne 0 ]                                              || return 3
   [ "$_res" == "" ]                                            || return 4

  ## Correct decorator and function declaration
  _res=$( $_func "$(cat << '   eol'
      
       @correctDecorator one two 

       @anotherDecorator three four \
         five    six
      function myfunc() {
        Whatever
      }
   eol
        )" | xargs
   ) && _ret=$? || _ret=$?
   [ $_ret -eq 0 ]                                              || return 5
   [ "$_res" == "one two three four five six" ]                               || return 6

} && tsh__add_func test__func_decorators

test__func_keyword() {
  local _func="func_keyword"

  ## Wrong function keyword
  _res=$( $_func "$(cat << '   eol'
    @decorator one two
    myfunction mfunc() {
      whatever
    }
   eol
        )"
  ) && _ret=$? || _ret=$?
  [ $_ret -ne 0 ]                                               || return 1
  [ "$_res" == "" ]                                             || return 2

  ## Correct function keyword
  _res=$( $_func "$(cat << '   eol'
    @decorator one two
    function mfunc() {
      whatever
    }
   eol
        )"
  ) && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 3
  [ "$_res" == "function" ]                                     || return 4

  ## No function keyword
  _res=$( $_func "$(cat << '   eol'
    @decorator one two
    mfunc() {
      whatever
    }
   eol
        )"
  ) && _ret=$? || _ret=$?
  [ $_ret -eq 0 ]                                               || return 5
  [ "$_res" == "" ]                                             || return 6

} && tsh__add_func test__func_keyword

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
