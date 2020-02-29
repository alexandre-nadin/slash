#!/usr/bin/env bash

dt::datetime() {
  #
  # Prints the current date-time.
  #
  date +%y-%m-%d' '%H:%M:%S
}

dt::resetRunDatetime() {
  #
  # (Re)Sets the script's starting date-time.
  #
  dt__RUN_DATETIME=($(dt::datetime))
}

dt::initRunDatetime() {
  #
  # Sets the script's starting date-time is not already done.
  #
  [ -z "${dt__RUN_DATETIME:+x}" ] && dt::resetRunDatetime || :
}

dt::runDatetime() {
  #
  # Prints the script's starting date-time
  #
  dt::initRunDatetime
  printf "${dt__RUN_DATETIME[@]}"
}

dt::runDate() {
  #
  # Prints the script's starting date.
  #
  dt::initRunDatetime
  printf "${dt__RUN_DATETIME[0]}"  
}

dt::runTime() {
  #
  # Prints the script's starting time.
  #   
  dt::initRunDatetime
  printf "${dt__RUN_DATETIME[1]}" 
}

dt::runDatetimeFileFormat() {
  #
  # Prints the script's starting date-time for file name.
  #
  dt::initRunDatetime
  dt::fileFormat "$(dt::runDate)_$(dt::runTime)"
}

dt::fileFormat() {
  #
  # Prints the standard date-time formatted for file names
  #
  local dt="${1:-$(dt::datetime)}"
  printf "$dt" \
   | sed -e 's| |_|g' \
         -e 's|:||g'  \
         -e 's|-||g'
}

dt::runDatetimeLogFormat() {
  #
  # Prints the script's starting date-time for logging.
  #
  dt::initRunDatetime
  printf "$(dt::runDate) $(dt::runTime)"
}

dt::logFormat() {
  #
  # Takes a date-time and formats it for file names
  # Takes standard date-time by default.
  #
  printf $(dt::datetime) 
}
