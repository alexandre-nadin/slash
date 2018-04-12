#!/usr/bin/env bash
source testsh.lib
source array-ref.lib

is_sourced() {
  #
  # Checks if the sourcing file has been sourced itself.
  #
  [ "${BASH_SOURCE[1]}" = "${0}" ] \
   && return 1 \
   || return 0

}

test__is_sourced() {
  cat << 'eol' > ${tsh__TEST_DIR}/test_sourced_1.sh
#!/usr/bin/env bash
source source.lib
is_sourced                                                      || exit 1
eol
  ! (bash ${tsh__TEST_DIR}/test_sourced_1.sh)                   || return 2
  (source ${tsh__TEST_DIR}/test_sourced_1.sh)                   || return 3

  cat << eol > ${tsh__TEST_DIR}/test_sourcing_1.sh
#!/usr/bin/env bash
source source.lib
is_sourced                                                      || exit 1
source "${tsh__TEST_DIR}/test_sourced_1.sh"                     || exit 2
! bash "${tsh__TEST_DIR}/test_sourced_1.sh"                     || exit 3
eol
  (source ${tsh__TEST_DIR}/test_sourcing_1.sh)                  || return 3

} && tsh__add_func test__is_sourced


# --------------------------
# Unique sourcing of files
# --------------------------
src__SOURCED_PREFIX="_srced__"
src__sourced_files=()

unique_source() {
  #
  # Sources a file only if it has not already been sourced.
  # Keeps track of each sourced file.
  #
  [ $# -eq 1 ]                                                  || return 1
  local _src="$1"
  # Strip the file name before sourcing it (no parenthesis)
  arrr_add_unique src__sourced_files $_src                      || return 2
  source $_src                                                  || return 3
   
}

test__unique_source() {
  local _func="unique_source"
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
  ! [ "$(echo "${src__sourced_files[@]}")"  == " logging.lib array-ref.lib" ] \
                                                                || return 9
  [ "$(echo "${src__sourced_files[@]}")" == "logging.lib array-ref.lib" ] \
                                                                || return 10

  # --------------
  # Deeper tests
  # --------------
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

