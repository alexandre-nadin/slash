#!/usr/bin/env bash
# -----------------
# Unique sourcing
# -----------------
## Here we make the first sourcing of source.lib to directly set source::unique available.
if type source::unique &> /dev/null; then
  source::unique source.lib || :
else
  source source.lib || return 2
fi

alias @slash-greet='read_funtemp; deco::defun <<< "$(slash::greet <<< "$funtemp")"' 
slash::greet() {
  #
  # Takes a template function in input and prepands a greeting line to its
  # recipe.
  #
  local _fun_template _fun_name _fun_recipe _fun_new
  _fun_template="${1:-$(io_existing_stdin)}"
  _fun_name=$(deco::func_name "$_fun_template")
  _fun_recipe=$(deco::func_recipe "$_fun_template")
  cat << eol
    ${_fun_name}() {
    echo "Greetings from '${FUNCNAME}'!"
    ${_fun_recipe}
  }
eol
}
