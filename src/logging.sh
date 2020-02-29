#!/usr/bin/env bash

# #############################################################################
# Simple way to use the library
# ============================================================================= 
#
# At any point in the script, we need to set the variable log__logFile using
# the function log::setLogFile "FILE_PATH"
# 
# Then using the following main functions:
# $ log::printVerbose "msg" 
# # Prints "msg" to STDERR only if the variable VERBOSE is set.
# 
# $ log::printInfo "msg"  
# # Prints "msg" in STDERR only if the variable VERBOSE is set. 
# # Writes "msg" in /log/dir/log_name.log only if log__logFile is 
#   declared and folder exists.
# 
# $ log::printError "msg" 
# # Prints "msg" in STDERR. 
# # Writes "msg" in /log/dir/log_name.err only if log__logFile is 
#   declared and folder exists.
# 
# $ log::exitError "msg"  
# # Prints "msg" in STDERR. 
# # Writes "msg" in /log/dir/log_name.log only if log__logFile is 
#   declared and folder exists. 
# # Exits with status 1
#
#
# #############################################################################
source datetime.sh

log__TYPE_INFO="INFO"
log__TYPE_ERROR="ERROR"
log__TYPE_WARNING="WARNING"
log__logFile=${log__logFile:-}  # Should be set with 'log::setLogFile' function.
log__LOG_EXT=".log"
log__ERR_EXT=".err"

# -------
# Modes
# -------
log::isDebugMode() {
  [ ! -z "${DEBUG:+x}" ]
}

log::isVerboseMode() {
  [ ! -z "${VERBOSE:+x}" ]
}

# --------------
# Log printing
# --------------
log::printVerbose() {
  #   
  # Prints input in stderr if in verbose mode.
  #
  [ -z "${VERBOSE:+x}" ] && return 0
  printf "$@\n" >&2
} && export -f log::printVerbose

log::printInfo() {
  #
  # Calls log::printVerbose because we don't want to display messages of type INFO 
  # by default, unless verbosity  VERBOSE is set.
  #
  log::printVerbose "$@"
  log::writeInfo "$@"
} && export -f log::printInfo

log::printWarning() {
  printf "WARNING: $@\n" >&2
  log::writeWarning "$@"
}

log::printDebug() {
  #
  # Prints debugging input in stderr if in DEBUG set.
  # Sets the verbosity on.
  # Resets the verbosity if was off before.
  #
  local wasVerbose=true
  log::isDebugMode || return 0
  log::isVerboseMode || wasVerbose=false
  VERBOSE=true
  log::printVerbose "DEBUG - $@" 
  [ ! -z "${wasVerbose:+x}" ] || unset VERBOSE 
} && export -f log::printDebug

log::printError() {
  #   
  # Prints input to stderr with error message.
  #
  printf "ERROR: $@\n" >&2
  log::writeError "$@"
} && export -f log::printError

log::exitError() {
  #   
  # Prints the input and exits with error.
  #
  log::printError "$@"
  exit 1
} && export -f log::exitError


# -----------------
# Logging library
# -----------------
log::setLogFile() {
  #
  # Sets the log file. Checks the directory.
  #
  log::isLogValid "$1" \
   && export log__logFile="$1" \
   || return 1
  log::printInfo "Starting logging."
}

log::isLogValid() {
  #
  # Takes a file path and checks that:
  #  - it is defined
  #  - it's directory exists
  #
  local _log_file=$(readlink -f "$1" 2> /dev/null)
  [ -z "${_log_file:+x}" ] && log::printError  "Provide a valide path for the log file (given '$1')." && return 1 || true
  local _dirname=$(dirname "$_log_file")
  [ ! -d "$_dirname" ] && log::printError "${FUNCNAME} - Dirname '$_dirname' does not exist." && return 1 || true
}

log::isLogWritable() {
  #
  # Tells if a log can be written by checking if :
  #  - log__logFile is defined
  #  - log__logFile's dirname is a directory
  #
  [ ! -z "${log__logFile:+x}" ] || return 1
  [ -d $(dirname "$log__logFile") ] || return 1
}

log::write() {
  #
  # Writes message in a log file if it is possible.
  #
  log::isLogWritable || return 0
  ## Writes output
  local log_type="$1" && shift
  local log_file="$1" && shift
  printf "[$(dt::logFormat)][$log_type][$BASHPID] $@\n" \
   >> "$log_file" \
   || printf "cannot write to $log_file.\n" >&2
}

log::writeInfo() {
  #
  # Writes informative message in a log file.
  #
  log::write "$log__TYPE_INFO" "${log__logFile}${log__LOG_EXT}" "$@"
}

log::writeWarning() {
  #
  # Writes warning message in a log file.
  #
  log::write "$log__TYPE_WARNING" "${log__logFile}${log__LOG_EXT}" "$@"
}

log::writeError() {
  #
  # Writes error message in a log file.
  #
  log::write "$log__TYPE_ERROR" "${log__logFile}${log__ERR_EXT}" "$@"
}
