#!/usr/bin/env bash
source testsh.lib
source array-ref.lib
source numbers.lib

is_sourced() {
  #
  # Checks if the sourcing file has been sourced itself.
  # 
  [ $# -ge 0 ]                                                  || return 1
  local _increm_bias=${1:-0}
  ++ _increm_bias     || return 2
  [ ${#BASH_SOURCE[@]} -gt 1 ]                                  || return 3
  ! [ "${BASH_SOURCE[${_increm_bias}]}" = "${0}" ]            || return 4 
}

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
source source.lib
is_sourced                                                      || exit 2
eol
  ! (bash $_f1)                                                 || return 3
  (source $_f1)                                                 || return 4

  cat << eol > $_f2
#!/usr/bin/env bash
source source.lib
is_sourced                                                      || exit 5
source "$_f1"                                                   || exit 6
! bash "$_f1"                                                   || exit 7
eol
  (source $_f2)                                                 || return $?

  ## Test incremental bias
  cat << eol > $_f3
#!/usr/bin/env bash
source source.lib
function f3_is_sourced() {
  is_sourced && return 0                                        || return 1
}
is_sourced                                                      || exit 8
eol
  (source $_f3; 
   f3_is_sourced                                                || exit 9
  )                                                             || return $?
} && tsh__add_func test__is_sourced


# --------------------------
# Unique sourcing of files
# --------------------------
shopt -s expand_aliases
alias 'src::source'='unique_source'

src__SOURCED_PREFIX="_srced__"
src__sourced_files=()

unique_source() {
  #
  # Sources a file only if it has not already been sourced.
  # Keeps track of each sourced file.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _src="$1"
  # Strip the file name before (passing without parenthesis)
  # 
  ! arrr_contains src__sourced_files $_src                      || return 2
  source $_src                                                  || return 3
  arrr_add_unique src__sourced_files $_src                      || return 4
}

test__unique_source() {
  # The file to source should:
  #  - not be registered
  #  - exist
  #  - be soured without error
  #  - registered
  local _func="unique_source" _ret
  # -------------
  # Basic tests
  # -------------
  ! $_func                                                      || return 1
  $_func logging.lib                                            || return 2
  ! $_func logging.lib                                          || return 3
  $_func array-ref.lib                                          || return 4
  ! $_func array-ref.lib                                        || return 5
  [ ${#src__sourced_files[@]} -eq 2 ]                           || return 6
 
  ! $_func " logging.lib"                                       || return 7
  [ ${#src__sourced_files[@]} -eq 2 ]                           || return 8

  $_func "loggi" &> /dev/null && _ret=$? || _ret=$?
  ! arrr_contains src__sourced_files "loggi"                    || return 9
  ! [ "$(echo "${src__sourced_files[@]}")"  == " logging.lib array-ref.lib" ] \
                                                                || return 10
  [ "$(echo "${src__sourced_files[@]}")" == "logging.lib array-ref.lib" ] \
                                                                || return 11

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
     && [ $SOURCED_VAR -eq 1 ])                                 || return 12

  ## File sourcing $_f1
  cat << eol > $_f2
#!/usr/bin/env bash
source $_f1                                                     || exit 13
source $_f1                                                     || exit 14
[ \$SOURCED_VAR -eq 2 ]                                         || exit 15
 
source source.lib
src::source $_f1                                                || exit 16
[ \$SOURCED_VAR -eq 3 ]                                         || exit 17

! src::source $_f1                                              || exit 18
[ \$SOURCED_VAR -eq 3 ]                                         || exit 19
eol

  (bash $_f2)                                                   || return $?

  ## File _f3 sourcing _f1
  cat << eol > $_f3
#!/usr/bin/env bash
source source.lib                                               || exit 20
src::source $_f1                                                || exit 21
source $_f1                                                     || exit 22
! src::source $_f1                                              || exit 23
[ \$SOURCED_VAR -eq 2 ]                                         || exit 24

eol
  (bash $_f3)                                                   || return $?

  ## File sourcing all
  cat << eol > $_f4
#!/usr/bin/env bash
source source.lib                                               || exit 25

src::source $_f3                                                || exit 26
[ \$SOURCED_VAR -eq 2 ]                                         || exit 27

! src::source $_f3                                              || exit 28
[ \$SOURCED_VAR -eq 2 ]                                         || exit 29

! src::source $_f1                                              || exit 30
[ \$SOURCED_VAR -eq 2 ]                                         || exit 31

source $_f1                                                     || exit 32
[ \$SOURCED_VAR -eq 3 ]                                         || exit 33

! src::source $_f1                                              || exit 34
[ \$SOURCED_VAR -eq 3 ]                                         || exit 35

src::source $_f0                                                || exit 36
eol
  (bash $_f4)                                                   || return $?
} && tsh__add_func test__unique_source


# ----
# Not reviewed
# -------------
_src_sourced_prefix="_sourced__"
function src__is_sourced() {
  #
  # Tells if the sourcing file has been sourced itself.
  #
  [[ "${BASH_SOURCE[1]}" = "${0}" ]] \
                                                                && return 1 \
                                                                || return 0
}


function src_source() {
  #
  # Registers the sourcing of the given files.
  #
  for sfile in "$@"; do
    src_source_file "$sfile" \
                                                                || return 1
  done
}

function src_source_uniq() {
  #
  # Sources the input files only if they haven't been registered as
  # already sourced.
  #
  for sfile in "$@"; do
    $(src_is_sourced "$sfile") \
     && echo -e "\"$sfile\" has already been sourced." >&2 \
     && continue \
     || src_source_file "$sfile" \
     || echo -e "Could not source \"$sfile\"." >&2 \
                                                                && return 1
  done
}

function src_source_file() {
  #
  # Registers the sourcing of the given file.
  # Exports a variable serving a flag purpose
  # src_source_file mfile.sh -> export ${_src_sourced_prefix}mfile.sh
  #
  set -euf -o pipefail
  local sfile="$1"
  local export_str=$(_src_file_to_export_str "$sfile")
  echo "sourcing $sfile" >&2
  #source "$sfile"
  echo "export: \$ $export_str" >&2
  eval "$export_str"
  set +euf +o pipefail
}

function _src_file_to_export_str() {
  # String to evaluate for exporting given variable as 'true'.
  local sfile="$1"
  echo "export $(_src_file_to_var $sfile)=true"
}

function _src_file_to_var() {
  echo "${_src_sourced_prefix}$1" \
    | tr ' ' '_'
}

function src_is_sourced() {
  #
  # Checks if file has already been registered as sourced.
  #
  local sfile="$1"
  local vfile=$(_src_file_to_var "$sfile")
  echo -e "checking variable \"$vfile\"= ${!vfile}" >&2
  [ -z "${!vfile:+x}" ] \
                                                                && return 1 \
                                                                || return 0
}

