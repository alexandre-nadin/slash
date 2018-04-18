#!/usr/bin/env bash
source source.sh
source::unique logging.lib
source::unique testslh.sh

set -euf -o pipefail
[ -z "${1:+x}" ] \
&& errexit "I need a library name to test."

file_path=$(cmd.realpath ${1} 2> /dev/null \
            || realpath ${1} 2> /dev/null)
[ ! -f "$file_path" ] \
&& errexit "File '$1' does not exist."

file_dir=$(dirname "$file_path")
file_bn=$(basename "$file_path")

test_path="${file_dir}/${tsh__TEST_FILE_PREXIX}${file_bn}"

[ -f "${test_path}" ] || errexit "Could not find testing file '${test_path}' to test '${file_path}'."

printf "[Testing '$1'] path: ${test_path}\n" >&2

#source "$file_path"  # -> Should be sourced in the testing file for more clarity I think
source "$test_path"
tsh__has_tests \
|| errexit "No tests found."
tsh__test_funcs
