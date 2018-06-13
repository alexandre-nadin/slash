#!/usr/bin/env bash
source script.sh

test__retexit() {
  local _func="retexit" _f{1..4} _ret

  _f0="${tsh__TEST_DIR}/test_script_retexit_0.sh"
  _f1="${tsh__TEST_DIR}/test_script_retexit_1.sh"
  
  cat << eol > $_f0
#!/usr/bin/env bash
source source.sh
set +eu
source $_f1
#echo "  _f1 ret: \$?"
exit $?

eol
  cat << eol > $_f1
#!/usr/bin/env bash
source script.sh
source source.sh
#is_sourced && echo " _f1 -> sourced" || echo " _f1 -> not sourced"

rexit
eol

  shopt -s expand_aliases                        
  alias rexit="is_sourced                                       && return 6 \
                                                                || exit 7" 

  (bash $_f1)  && _ret=$? || _ret=$?
  #echo " _ret: $_ret"
  [ $_ret -eq 7 ]                                               || return 1

  (source $_f1)  && _ret=$? || _ret=$?
  #echo " _ret: $_ret"
  [ $_ret -eq 6 ]                                               || return 2


  (bash $_f0)  && _ret=$? || _ret=$?
  #echo " _ret: $_ret"
  [ $_ret -eq 6 ]                                               || return 3

  #(source $_f0)  && _ret=$? || _ret=$?
  #echo " _ret: $_ret"
  #[ $_ret -eq 6 ]                                              || return 4
} && tsh__add_func test__retexit
