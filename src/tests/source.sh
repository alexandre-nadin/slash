#!/usr/bin/env bash
source source.sh
source testslh.sh

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
} && tsh::addFunc test__source::cleanSource

test__source::isFileSourced() {
  local _func="source::uniqueStrict" _ret _f{1..3}
  _f1=${tsh__TEST_DIR}/test__source_source::isFileSourced_1.sh
  _f2=${tsh__TEST_DIR}/test__source_source::isFileSourced_2.sh
  _f3=${tsh__TEST_DIR}/test__source_source::isFileSourced_3.sh

  ## Test if self sourced? 
  source::isFileSourced                     ; tsh::expectStatus 1:0

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
} && tsh::addFunc test__source::isFileSourced

test__source::resetSources() {
  local _func="source::resetSources" _ret
  ! $_func one two                                              || return 1
  $_func                                                        || return 2
  [ "${#src__sourcedFiles[@]}" -eq 1 ]                          || return 3
  src__sourcedFiles=(one two three)                             || return 4
  [ "${#src__sourcedFiles[@]}" -eq 3 ]                          || return 5
  $_func                                                        || return 6
  $_func                                                        || return 7
  [ "${#src__sourcedFiles[@]}" -eq 1 ]                          || return 8
} && tsh::addFunc test__source::resetSources

test__source::addSource() {
  local _func="source::addSource" _ret
  $_func; [ $? -eq 1 ]  || return 1
  $_func "testslh.sh"; [ $? -eq 0 ] || return 2
  $_func "testslh.sh"; [ ${#src__sourcedFiles[@]} -eq 3 ] || return 3
   
} && tsh::addFunc test__source::addSource

test__source::containsSource() {
  local _func="source::containsSource" _ret
  source::resetSources                                          || return 1
  $_func                                         ; [ $? -eq 1 ] || return 2
  $_func "source.sh"                            ; [ $? -eq 0 ] || return 3
  $_func "testslh.sh"                            ; [ $? -eq 2 ] || return 4
  source::addSource "testslh.sh"                                || return 5
  $_func "testslh.sh"                            ; [ $? -eq 0 ] || return 6
  src__sourcedFiles=()
  $_func "testslh.sh"                            ; [ $? -eq 2 ] || return 7
} && tsh::addFunc test__source::containsSource

test__source::addSourceUnique() {
  local _func="source::addSourceUnique" _ret
  source::resetSources                                          || return 1
  $_func                    ; [ $? -eq 1 ] || return 2
  $_func first  ; [ $? -eq 0 ] || return 3
  $_func second                                                 || return 4
  $_func " first"                                               || return 5
  $_func "first"   ; [ $? -eq 2 ] ||  return 6
  [ "$(echo "${src__sourcedFiles[@]}")" \
      == "source.sh first second  first" ]                      || return 7
} && tsh::addFunc test__source::addSourceUnique

test__source::removeSourceUnique() {
  local _func="source::removeSourceUnique" _ret
  source::resetSources                                          || return 1
  ! $_func                                                      || return 2
  [ ${#src__sourcedFiles[@]} -eq 1 ]                            || return 3
  ! $_func first                                                || return 4
  ! $_func second                                               || return 5
  source::addSourceUnique "first"                               || return 6
  source::addSourceUnique "second"                              || return 7
  source::addSourceUnique " first"                              || return 8
  [ ${#src__sourcedFiles[@]} -eq 4 ]                            || return 9
  ! $_func "  first"                                            || return 10
  $_func " first"                                               || return 11
  $_func "first"                                                || return 12
  [ ${#src__sourcedFiles[@]} -eq 2  ]                           || return 13
  source::addSourceUnique "first"                               || return 14
} && tsh::addFunc test__source::removeSourceUnique

test__source::uniqueStrict() {
  # The file to source should:
  #  - not be registered
  #  - exist
  #  - be soured without error
  #  - registered
  local _func="source::uniqueStrict" _ret
  source::resetSources                                          || return 1
  # -------------
  # Basic tests
  # -------------
  ! $_func                                                      || return 2
  
  $_func logging.lib                                            || return 3
  ! $_func logging.lib                                          || return 4
  $_func array.sh                                               || return 5
  ! $_func array.sh                                             || return 6
  [ ${#src__sourcedFiles[@]} -eq 3 ]                            || return 7
 
  ! $_func " logging.lib"                                       || return 8
  [ ${#src__sourcedFiles[@]} -eq 3 ]                            || return 9

  ! $_func "loggi" &> /dev/null                                 || return 10
  ! source::containsSource "loggi"                              || return 11
  ! [ "$(echo "${src__sourcedFiles[@]}")"  == " logging.lib array.sh" ]     \
                                                                || return 12
  [ "$(echo "${src__sourcedFiles[@]}")" \
     == "source.sh logging.lib array.sh" ] \
                                                                || return 13

  # --------------
  # Deeper tests
  # --------------
  ## Testing script files
  local _f{1..4}
  _f0="${tsh__TEST_DIR}/test_source::uniqueStrict_0.sh"
  _f1="${tsh__TEST_DIR}/test_source::uniqueStrict_1.sh"
  _f2="${tsh__TEST_DIR}/test_source::uniqueStrict_2.sh"
  _f3="${tsh__TEST_DIR}/test_source::uniqueStrict_3.sh"
  _f4="${tsh__TEST_DIR}/test_source::uniqueStrict_4.sh"

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
echo "src__sourcedFiles: \${src__sourcedFiles[@]}"
[ \$SOURCED_VAR -eq 2 ]                                         || retexit 28

echo "src__sourcedFiles: \${src__sourcedFiles[@]}"
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
} && tsh::addFunc test__source::uniqueStrict
