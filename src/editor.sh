#!/usr/bin/env bash
source logging.sh

editor__EDITORS=(vim vi nano)

editor::isSet() {
  [ ! -z "${EDITOR:+x}" ]
}

editor::setEditor() {
  export EDITOR="${1:-$(editor::default)}"
}

editor::default() {
  for _editor in "${editor__EDITORS[@]}"; do
    type "$_editor" &> /dev/null \
     && printf $_editor          \
     && break \
     || log::printVerbose "Couldn't set editor to \"$_editor\"."
  done
  if editor::isSet; then
    :
  else
    log::printWarning "No default editor found among (${editor__EDITORS[@]})"
    return 1
  fi
}

editor::setEditorDefault() {
  #
  # Sets the first default EDITOR found in editor__EDITORS
  # if none is already set.
  #
  ! editor::isSet || {
    log::printVerbose "Editor already set to '$EDITOR'."
    return 0
  }
  editor::setEditor
} && editor::setEditorDefault
