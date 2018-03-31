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
source io.lib
source decorator.sh

slash::safesource() {
  :
}


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

set +euf +o pipefail
