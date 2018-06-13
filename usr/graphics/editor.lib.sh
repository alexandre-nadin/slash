#!/usr/bin/env sh
source logging.lib

# -------------
# Text Editor
# -------------
_editors=(vim vi nano)
function set_text_editor() {
  export EDITOR="$1"
}

function set_default_editor() {
  #
  # Sets the first default EDITOR found in _editors
  # if none is already set.
  #
  [ -z "${EDITOR:+x}" ] || {
    verbecho "Editor already set to '$EDITOR'."
    return 0
  }
  for _editor in "${_editors[@]}"; do
    type "$_editor" &> /dev/null \
     && set_text_editor "$_editor" \
     && verbecho "Set default editor to \"$_editor\"" \
     && break \
     || verbecho "Couldn't set editor to \"$_editor\""
  done
}
set_default_editor
