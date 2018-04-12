#!/usr/bin/env bash
source testsh.lib

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
echo "BASH_SOURCE[@]: '${BASH_SOURCE[@]}'"
source source.lib
is_sourced                                                      || exit 1
eol
  ! (bash ${tsh__TEST_DIR}/test_sourced_1.sh)                   || return 2
  (source ${tsh__TEST_DIR}/test_sourced_1.sh)                   || return 3

  cat << eol > ${tsh__TEST_DIR}/test_sourcing_1.sh
#!/usr/bin/env bash
source source.lib
is_sourced                                                      || exit 1
echo "BASH_SOURCE[@]: '\${BASH_SOURCE[@]}'"
source "${tsh__TEST_DIR}/test_sourced_1.sh"                     || exit 2
! bash "${tsh__TEST_DIR}/test_sourced_1.sh"                     || exit 3
eol
  (source ${tsh__TEST_DIR}/test_sourcing_1.sh)                  || return 3

} && tsh__add_func test__is_sourced

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
