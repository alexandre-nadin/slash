#!/usr/bin/env bash
source source.sh

test__source::cleanSource() {
  local _func="source::cleanSource" _ret _f1
  _f1=${tsh__TEST_DIR}/test__source_source::isFileSourced_1.sh

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
} && tsh__add_func test__source::cleanSource

test__source::isFileSourced() {
  local _func="unique_source" _ret _f{1..3}
  _f1=${tsh__TEST_DIR}/test__source_source::isFileSourced_1.sh
  _f2=${tsh__TEST_DIR}/test__source_source::isFileSourced_2.sh
  _f3=${tsh__TEST_DIR}/test__source_source::isFileSourced_3.sh

  ## Test if self sourced? 
  source::isFileSourced                                         || return 1

  ## Test if executed or sourced
  cat << 'eol' > $_f1
#!/usr/bin/env bash
source source.sh
source::isFileSourced                                           || exit 2
eol
  ! (bash $_f1)                                                 || return 3
  (source $_f1)                                                 || return 4

  cat << eol > $_f2
#!/usr/bin/env bash
source source.sh
source::isFileSourced                                           || exit 5
source "$_f1"                                                   || exit 6
! bash "$_f1"                                                   || exit 7
eol
  (source $_f2)                                                 || return $?

  ## Test incremental bias
  cat << eol > $_f3
#!/usr/bin/env bash
source source.sh
function f3_source::isFileSourced() {
  source::isFileSourced                                         && return 0 \
                                                                || return 1
}
source::isFileSourced                                           || exit 8
eol
  (source $_f3; 
   f3_source::isFileSourced                                     || exit 9
  )                                                             || return $?
} && tsh__add_func test__source::isFileSourced

test__reset_unique_source_files() {
  local _func="reset_unique_source_files" _ret
  ! $_func one two                                              || return 1
  $_func                                                        || return 2
  [ "${#src__sourced_files[@]}" -eq 1 ]                         || return 3
  src__sourced_files=(one two three)                            || return 4
  [ "${#src__sourced_files[@]}" -eq 3 ]                         || return 5
  $_func                                                        || return 6
  $_func                                                        || return 7
  [ "${#src__sourced_files[@]}" -eq 1 ]                         || return 8
} && tsh__add_func test__reset_unique_source_files

test__source::hasSourcedFiles() {
  local _func="source::hasSourcedFiles" _ret
  reset_unique_source_files                                     || return 1
  $_func one                                                    || return 2
  $_func                                                        || return 3 

} && tsh__add_func test__source::hasSourcedFiles

test__source::containsSource() {
  local _func="source::containsSource" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  $_func "source.sh"                                            || return 3
  src__sourced_files=()
  ! $_func                                                      || return 4
} && tsh__add_func test__source::containsSource

test__source::addSourceUnique() {
  local _func="source::addSourceUnique" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  $_func first                                                  || return 3
  $_func second                                                 || return 4
  $_func " first"                                               || return 5
  ! $_func "first"                                              || return 6
  [ "$(echo "${src__sourced_files[@]}")" \
      == "source.sh first second  first" ]                      || return 7
} && tsh__add_func test__source::addSourceUnique

test__source::removeSourceUnique() {
  local _func="source::removeSourceUnique" _ret
  reset_unique_source_files                                     || return 1
  ! $_func                                                      || return 2
  [ ${#src__sourced_files[@]} -eq 1 ]                           || return 3
  ! $_func first                                                || return 4
  ! $_func second                                               || return 5
  source::addSourceUnique "first"                               || return 6
  source::addSourceUnique "second"                              || return 7
  source::addSourceUnique " first"                              || return 8
  [ ${#src__sourced_files[@]} -eq 4 ]                           || return 9
  ! $_func "  first"                                            || return 10
  $_func " first"                                               || return 11
  $_func "first"                                                || return 12
  [ ${#src__sourced_files[@]} -eq 2  ]                          || return 13
  source::addSourceUnique "first"                               || return 14
} && tsh__add_func test__source::removeSourceUnique

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
  $_func array.sh                                               || return 5
  ! $_func array.sh                                             || return 6
  [ ${#src__sourced_files[@]} -eq 3 ]                           || return 7
 
  ! $_func " logging.lib"                                       || return 8
  [ ${#src__sourced_files[@]} -eq 3 ]                           || return 9

  ! $_func "loggi" &> /dev/null                                 || return 10
  ! source::containsSource "loggi"                              || return 11
  ! [ "$(echo "${src__sourced_files[@]}")"  == " logging.lib array.sh" ]     \
                                                                || return 12
  [ "$(echo "${src__sourced_files[@]}")" \
     == "source.sh logging.lib array.sh" ] \
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
