#!/usr/bin/env sh
source logging.lib
source trap.lib
source array-ref.lib

## List of tracked temporary files.
_tmp_tmp_files=() 

function tmp_reset_files() {
  _tmp_tmp_files=()
}

function _tmp_rm_all() {
  #
  # Removes all recorded temp files.
  #
  [ ${#_tmp_tmp_files[@]} -eq 0 ] \
   && return 0 \
   || :
  rm -f "${_tmp_tmp_files[@]}"
}

function tmp_rm() {
  #
  # Removes the given temp file.
  # Check the temp file is being tracked first.
  #
  local tmp_file="$1"
 
  ## Check tmep file is being tracked.
  ! arrr_contains _tmp_tmp_files "$tmp_file" \
   && errecho "Temp file '$tmp_file' is not being tracked." \
   && return 1 \
   || :

  ## Remove temp file
  [ -f "$tmp_file" ] \
   && rm "$tmp_file" \
   || { 
       errecho "Cannot remove temp file '$tmp_file'." \
        && return 1
      }

  ## Untrack temp file
  arrr_pop_name _tmp_tmp_files "$tmp_file" &> /dev/null \
   || {
       errecho "Failed to pop '$tmp_file' out of tracked files." \
       && return 1
      }
}

function _tmp_add_files() {
  #
  # Creates a temp file, touches it and assign it to the
  # given variable name.
  #
  for tfile in "$@"; do
    ! touch "$tfile" \
     && errecho "${FUNCNAME} - Couldn't touch temp file \"$tfile\"." \
     && return 1 \
     || :
    _tmp_tmp_files+=("$tfile")
    debugecho "added tfile: $tfile"
  done
}

function tmp_set_tmp_dir() {
  #
  # Sets default temp dir
  #
  [ ! -d "$1" ] \
   && errecho "${FUNCNAME} - Not a directory: \"$1\"" \
   && return 1 \
   || TMPDIR="$1"
}

function tmp_declare_tmp_file() {
  #
  # Takes name of a variable and assigns a temporary file to it.
  # By default, the temp file name will be given by `mktemp`
  # if the 
  #
  local file_var="$1"
  local tmp_file="$(mktemp)"
  _tmp_add_files "$tmp_file" 
  ! eval "$file_var=\"$tmp_file\"" \
   && errecho "${FUNCNAME} - Cannot evaluate variable '$file_var'" \
   || :
}

## Add cleaning function to EXIT and SIGINT traps.
trap_add_func _tmp_rm_all EXIT SIGINT
