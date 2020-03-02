#!/usr/bin/env bash
source script.sh
source testslh.sh

script::returnOrExitTest() {
  local _func="script::returnOrExit" _f{1..4} _ret

  echo "tsh__DIR: '${tsh__DIR}'" >&2
  _f0="${tsh__TEST_DIR}/script::returnOrExit_0.sh"
  _f1="${tsh__TEST_DIR}/script::returnOrExit_1.sh"
  
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
#source::isFileSourced && echo " _f1 -> sourced" >&2 || echo " _f1 -> not sourced" >&2

script::rexit
eol

  shopt -s expand_aliases                        
  alias script::rexit="source::isFileSourced && return 6 || exit 7" 
  (bash $_f1); tsh::expectStatus 1:7
  #(bash $_f1)  && _ret=$? || _ret=$?
  ##echo " _ret: $_ret"
  #[ $_ret -eq 7 ]                                               || return 1

  (source $_f1); tsh::expectStatus 2:6
  #(source $_f1)  && _ret=$? || _ret=$?
  ##echo " _ret: $_ret"
  #[ $_ret -eq 6 ]                                               || return 2


  (bash $_f0); tsh::expectStatus 3:6
  #(bash $_f0)  && _ret=$? || _ret=$?
  ##echo " _ret: $_ret"
  #[ $_ret -eq 6 ]                                               || return 3

  #(source $_f0)  && _ret=$? || _ret=$?
  #echo " _ret: $_ret"
  #[ $_ret -eq 6 ]                                              || return 4
} && tsh::addFunc script::returnOrExitTest
