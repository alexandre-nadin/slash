#!/usr/bin/env bash
safe_source() {
  #
  # Saves the current shell set options before sourcing the given file.
  # Restores them afterwards.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _setoptions _ret
  _ret=0
  _setoptions=$(set +o | sed 's/$/;/g')  || _ret=1
  set +o history
  unset HISTFILE
  source "$1" || _ret=2 
  eval "$_setoptions" || _ret=3
  return $_ret
}

#safe_source array.sh

is_sourced() {
  #
  # Checks if the sourcing file has been sourced itself.
  # 
  [ $# -ge 0 ]                                                  || return 1
  local _increm_bias=${1:-0}
  _increm_bias=$(( _increm_bias + 1 ))                          || return 2
  [ ${#BASH_SOURCE[@]} -gt 1 ]                                  || return 3
  ! [ "${BASH_SOURCE[${_increm_bias}]}" = "${0}" ]              || return 4 
}


# --------------------------
# Unique sourcing of files
# --------------------------
src__SOURCED_PREFIX="_srced__"

reset_unique_source_files() {
  #
  # Resets the array of unique sourced files.
  #
  [ $# -eq 0 ]                                                  || return 1
  src__sourced_files=("$(basename ${BASH_SOURCE[1]})")          || return 2
} && reset_unique_source_files

is_source_list_empty() {
  [ ${#src__sourced_files[@]} -eq 0 ]
}

contains_source() {
  [ $# -eq 1 ]  || return 1
  ! is_source_list_empty \
  && grep -q -s " $1 " <<< " ${src__sourced_files[@]} "     || return 2
}

add_source() {
  [ $# -eq 1 ]  || return 1
  src__sourced_files+=("$1")
}

add_unique_source() {
  #
  # Adds the given string to a list of tracked files it is does not already
  # exist.
  #
  [ $# -eq 1 ]                                                  || return 1
  ! contains_source "$1" \
   && add_source "$1"           || return 2
}

remove_unique_source() {
  #
  # Removes the given string from the list of tracked files if it exists.
  #
  [ $# -eq 1 ]                                                  || return 1
  ! is_source_list_empty        || return 2
  contains_source "$1"   || return 3
  local _tmp_arr
  for _src in "${src__sourced_files[@]}"; do
    [ "$_src" == "$1" ] \
     || _tmp_arr+=("$_src") 
  done 
  src__sourced_files=($(echo "${_tmp_arr[@]}"))  || return 4

}

# ------------------------------------------------------------------------------ 
# Unique sourcing
#
# 'unique_source' is the function that does the unique sourcing. It returns a 
# non-zero value if the sourcing cannot be done. It is used for the tests.
# 'usource' and 'source::unique_strict' are the kindof front-end functions call 
# 'unique_source'. Those may be used in your script. 'source::unique' does the same
# except if always returns 0. Use with caution then, with tested scripts and librares. 
#
# ------------------------------------------------------------------------------
usource() {
  unique_source "$@"                                            || return $?
}

source::unique() {
  #
  # Sources the given file only if it has not already been sourced.
  # Return status is always 0, to be used for ignoring redundant sourcing.
  # Use if you are sure the library required do exist and are tested.
  #
  unique_source "$@" || :
}

source::unique_strict() {
  #
  # Sources the given file only if it has not already been sourced.
  # Return error status if it cannot source it.
  #
  unique_source "$@"                                            || return $?
} 

unique_source() {
  #
  # Sources a file only if it has not already been sourced.
  # Save the provided file name.
  # Sources it. Removes it if sourcing failes.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _src="$1" _ret=0
  # Strip the file name before (passing without parenthesis)
  add_unique_source $_src                                       || return 2
  if safe_source $_src; then
    return 0
  else
    remove_unique_source $_src                                  && return 4 \
                           || return 3
  fi
}


# ----
# Auto adds itself to the list of sourced libs
#add_unique_source "$(basename ${BASH_SOURCE[0]})"

# -------
# Tests
# -------
source::unique testslh.sh
test__safe_source() {
  local _func="safe_source" _ret _f1
  _f1=${tsh__TEST_DIR}/test__source_is_sourced_1.sh

  ## Test if executed or sourced
  cat << 'eol' > $_f1
#!/usr/bin/env bash
set -euf -o pipefail
ercho &> /dev/null                                              || return 1
echo "You should not see this." >&2 
return 0
eol
#  (set +euf; set -o; 
#   source $_f1; echo "failed? $?"; 
#   set -euf; echo hi; true; echo ho; false; echo hu 
#  )
  return 7
  set -euf
  (set -euf; echo hi; true; echo ho; false; echo hu)
  echo "?: $?"
  set -euf 
  erccho &>/dev/null
  echo passed
  [ $? -eq 0 ]                                                  || return 1
  #(source $_f1 && echo sourced _f2|| echo failed sourcing _f2) || return 4
} && tsh__add_func test__safe_source

test__is_sourced() {
  local _func="unique_source" _ret _f{1..3}
  _f1=${tsh__TEST_DIR}/test__source_is_sourced_1.sh
  _f2=${tsh__TEST_DIR}/test__source_is_sourced_2.sh
  _f3=${tsh__TEST_DIR}/test__source_is_sourced_3.sh

  ## Test if self sourced? 
  is_sourced                                                    || return 1

  ## Test if executed or sourced
  cat << 'eol' > $_f1
#!/usr/bin/env bash
source source.sh
is_sourced                                                      || exit 2
eol
  ! (bash $_f1)                                                 || return 3
  (source $_f1)                                                 || return 4

  cat << eol > $_f2
#!/usr/bin/env bash
source source.sh
is_sourced                                                      || exit 5
source "$_f1"                                                   || exit 6
! bash "$_f1"                                                   || exit 7
eol
  (source $_f2)                                                 || return $?

  ## Test incremental bias
  cat << eol > $_f3
#!/usr/bin/env bash
source source.sh
function f3_is_sourced() {
  is_sourced                                                    && return 0 \
                                                                || return 1
}
is_sourced                                                      || exit 8
eol
  (source $_f3; 
   f3_is_sourced                                                || exit 9
  )                                                             || return $?
} && tsh__add_func test__is_sourced

test__reset_unique_source_files() {
  local _func="reset_unique_source_files" _ret
  ! $_func one two                                              || return 1
  [ "${#src__sourced_files[@]}" -eq 2 ]                         || return 2
  src__sourced_files=(one two three)                            || return 3
  [ "${#src__sourced_files[@]}" -eq 3 ]                         || return 4
  $_func                                                        || return 5
  $_func                                                        || return 6
  [ "${#src__sourced_files[@]}" -eq 1 ]                         || return 7
} && tsh__add_func test__reset_unique_source_files

test__is_source_list_empty() {
  local _func="is_source_list_empty" _ret
  reset_unique_source_files                                     || return 1
  ! $_func one                                                  || return 2
  ! $_func   || return 3 

} && tsh__add_func test__is_source_list_empty

test__contains_source() {
  local _func="contains_source" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  $_func "source.sh"                    || return 3
  src__sourced_files=()
  ! $_func  || return 4
} && tsh__add_func test__contains_source

test__add_unique_source() {
  local _func="add_unique_source" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  $_func first                                                  || return 3
  $_func second                                                 || return 4
  $_func " first"                                               || return 5
  ! $_func "first"                                              || return 6
  [ "$(echo "${src__sourced_files[@]}")" \
      == "$(basename ${BASH_SOURCE[0]}) first second  first" ]  || return 7
} && tsh__add_func test__add_unique_source

test__remove_unique_source() {
  local _func="remove_unique_source" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  [ ${#src__sourced_files[@]} -eq 1 ]                           || return 3
  ! $_func first                                                || return 4
  ! $_func second                                               || return 5
  add_unique_source "first"                                     || return 6
  add_unique_source "second"                                    || return 7
  add_unique_source " first"                                    || return 8
  [ ${#src__sourced_files[@]} -eq 4 ]                           || return 9
  ! $_func "  first"                                            || return 10
  $_func " first"                                               || return 11
  $_func "first"                                                || return 12
  [ ${#src__sourced_files[@]} -eq 2  ]                          || return 13
  add_unique_source "first"                                     || return 14
} && tsh__add_func test__remove_unique_source

test__unique_source() {
  # The file to source should:
  #  - not be registered
  #  - exist
  #  - be soured without error
  #  - registered
  local _func="unique_source" _ret
  reset_unique_source_files                                     || return 1
  # -------------
  # Basic tests
  # -------------
  ! $_func                                                      || return 2
  
  $_func logging.lib                                            || return 3
  ! $_func logging.lib                                          || return 4
  $_func array.sh                                          || return 5
  ! $_func array.sh                                        || return 6
  [ ${#src__sourced_files[@]} -eq 3 ]                           || return 7
 
  ! $_func " logging.lib"                                       || return 8
  [ ${#src__sourced_files[@]} -eq 3 ]                           || return 9

  ! $_func "loggi" &> /dev/null || return 10
  ! contains_source "loggi"                    || return 11
  ! [ "$(echo "${src__sourced_files[@]}")"  == " logging.lib array.sh" ] \
                                                                || return 12
  [ "$(echo "${src__sourced_files[@]}")" \
     == "$(basename ${BASH_SOURCE[0]}) logging.lib array.sh" ] \
                                                                || return 13

  # --------------
  # Deeper tests
  # --------------
  ## Testing script files
  local _f{1..4}
  _f0="${tsh__TEST_DIR}/test_unique_source_0.sh"
  _f1="${tsh__TEST_DIR}/test_unique_source_1.sh"
  _f2="${tsh__TEST_DIR}/test_unique_source_2.sh"
  _f3="${tsh__TEST_DIR}/test_unique_source_3.sh"
  _f4="${tsh__TEST_DIR}/test_unique_source_4.sh"

  ## Empty file
  cat << 'eol' > $_f0
#!/usr/bin/env bash
eol

  ## File to be sourced
  cat << 'eol' > $_f1
#!/usr/bin/env bash

## Init at 0 if not defined or empty
set +u
SOURCED_VAR=${SOURCED_VAR:-0}

## Increment
SOURCED_VAR=$(( SOURCED_VAR + 1 ))
eol

  (source $_f1 \
     && [ ! -z ${SOURCED_VAR:+x} ] \
     && [ $SOURCED_VAR -eq 1 ])                                 || return 13

  ## File sourcing $_f1
  cat << eol > $_f2
#!/usr/bin/env bash
source script.sh
source $_f1                                                     || retexit 14
source $_f1                                                     || retexit 15
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 16
 
source source.sh
source::unique $_f1                                             || retexit 17
[ \$SOURCED_VAR -eq 3 ]                                         || retexit 18

! source::unique $_f1                                           || retexit 19
[ \$SOURCED_VAR -eq 3 ]                                         || retexit 20
eol

  (bash $_f2)                                                   || return $?
  unset SOURCED_VAR

return 0
  ## File _f3 sourcing _f1
  cat << eol > $_f3
#!/usr/bin/env bash
echo "Being sourced (BASH_SOURCE:\${BASH_SOURCE[@]}"
source script.sh
source source.sh                                                || retexit 21

source::unique $_f1                                             || retexit 22
source $_f1                                                     || retexit 23
! source::unique $_f1                                           || retexit 24
#echo "SOURCED_VAR: \$SOURCED_VAR"
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 25

eol
  unset SOURCED_VAR
  (bash $_f3)                                                   || return $?

  ## File sourcing all
  cat << eol > $_f4
#!/usr/bin/env bash
source source.sj                                                || retexit 26

echo "[add F3]"
source::unique $_f3                                             || retexit 27
echo "src__sourced_files: \${src__sourced_files[@]}"
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 28

echo "src__sourced_files: \${src__sourced_files[@]}"
retexit 77
source::unique $_f3 && _ret=\$? || _ret=\$?
echo "_ret: \$_ret; SOURCED_VAR: \$SOURCED_VAR"
#[ \$_ret -eq 25                                                || retexit 29
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 30

! source::unique $_f1                                           || retexit 31
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 32

source $_f1                                                     || retexit 33
[ \$SOURCED_VAR -eq 3 ]                                         || retexit 34

! source::unique $_f1                                           || retexit 35
[ \$SOURCED_VAR -eq 3 ]                                         || retexit 36

source::unique $_f0                                             || retexit 37
eol
  unset SOURCED_VAR
  (bash $_f4)                                                   || return $?
} && tsh__add_func test__unique_source
