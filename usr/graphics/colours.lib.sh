#!/usr/bin/env sh
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
source variable.lib

clrf_escapes=('\e' '\033' '\x1B')
clrf_code_sep=';'

function _filter_list() {
  #
  # Filters the given list based on the first parameter
  #
  local results=()
  local filter="$1" && shift
  local elem=
  for elem in "$@"; do
    results+=($(echo " $elem " | grep "$filter"))
  done
  echo "${results[@]}"
}

color_formats=(
  clrf_reset_all_attributes # 0
  clrf_set_bold_bright # 1
  clrf_set_dim # 2
  clrf_ukn_3 # 3
  clrf_set_underlined # 4
  clrf_set_blink # 5
  clrf_ukn_6 # 6
  clrf_set_reverse # 7
  clrf_set_hidden # 8
   clrf_unknown # 9
   clrf_unknown # 10
   clrf_unknown # 11
   clrf_unknown # 12
   clrf_unknown # 13
   clrf_unknown # 14
   clrf_unknown # 15
   clrf_unknown # 16
   clrf_unknown # 17
   clrf_unknown # 18
   clrf_unknown # 19
   clrf_unknown # 20
  clrf_reset_bold_bright # 21
  clrf_reset_dim # 22
  clrf_ukn_23 # 23
  clrf_reset_underlined # 24
  clrf_reset_blink # 25
  clrf_ukn_26 # 26
  clrf_reset_reverse # 27
  clrf_reset_hidden # 28
   clrf_unknown # 29
  clrf_fg_black # 30
  clrf_fg_red # 31
  clrf_fg_green # 32
  clrf_fg_yellow # 33
  clrf_fg_blue # 34
  clrf_fg_magenta # 35
  clrf_fg_cyan # 36
  clrf_fg_gray_light # 37
  clrf_fg_extended # 38
  clrf_fg_default # 39
  clrf_bg_black # 40
  clrf_bg_red # 41
  clrf_bg_green # 42
  clrf_bg_yellow # 43
  clrf_bg_blue # 44
  clrf_bg_magenta # 45
  clrf_bg_cyan # 46
  clrf_bg_gray_light # 47
  clrf_bg_extended # 48
  clrf_bg_default # 49
   clrf_unknown # 50
   clrf_unknown # 51
   clrf_unknown # 52
   clrf_unknown # 53
   clrf_unknown # 54
   clrf_unknown # 55
   clrf_unknown # 56
   clrf_unknown # 57
   clrf_unknown # 58
   clrf_unknown # 59
   clrf_unknown # 60
   clrf_unknown # 61
   clrf_unknown # 62
   clrf_unknown # 63
   clrf_unknown # 64
   clrf_unknown # 65
   clrf_unknown # 66
   clrf_unknown # 67
   clrf_unknown # 68
   clrf_unknown # 69
   clrf_unknown # 70
   clrf_unknown # 71
   clrf_unknown # 72
   clrf_unknown # 73
   clrf_unknown # 74
   clrf_unknown # 75
   clrf_unknown # 76
   clrf_unknown # 77
   clrf_unknown # 78
   clrf_unknown # 79
   clrf_unknown # 80
   clrf_unknown # 81
   clrf_unknown # 82
   clrf_unknown # 83
   clrf_unknown # 84
   clrf_unknown # 85
   clrf_unknown # 86
   clrf_unknown # 87
   clrf_unknown # 88
   clrf_unknown # 89
  clrf_fg_gray_dark # 90
  clrf_fg_red_light # 91
  clrf_fg_green_light # 92
  clrf_fg_yellow_light # 93
  clrf_fg_blue_light # 94
  clrf_fg_magenta_light # 95
  clrf_fg_cyan_light # 96
  clrf_fg_white # 97
   clrf_unknown # 98
   clrf_unknown # 99
  clrf_bg_gray_dark # 100
  clrf_bg_red_light # 101
  clrf_bg_green_light # 102
  clrf_bg_yellow_light # 103
  clrf_bg_blue_light # 104
  clrf_bg_magenta_light # 105
  clrf_bg_cyan_light # 106
  clrf_bg_white # 107
)
## Declare variables
var_enum_vars 0 ${color_formats[@]}

clrf_format_codes() {
  #
  # Takes ansi codes in input and formats them.
  #
  echo "${clrf_escapes[0]}[$(str.join -d ${clrf_code_sep} $@)m" 
}

clrf_codify_str() {
  #
  # Formats the given string with the given following codes.
  #
  local astring="$1" && shift
  local result+="$(clrf_format_codes $@)"
  result+="$astring"
  result+="$(clrf_format_codes $clrf_reset_all_attributes)"
  echo "$result"
}

clrf_format_codes_256() {
  ## Unfinished
  local result 
  echo "${clrf_escapes[0]}[$(str.join -d ${clrf_code_sep} $@)m"
}

clrf_echo() {
  local astring="$1" && shift
  echo -e $(clrf_codify_str "$astring" "$@") 
}

clrf_echo256() {
  ## Unfinished
  echo "finish this"
}

clrf_print_256() {
  #
  # Prints the 256 colors in fore/back ground
  #
  for fgbg in 38 48 ; do #Foreground/Background
    for color in {0..256} ; do #Colors
      #Display the color
      echo -en "\e[${fgbg};5;${color}m ${color}\t\e[0m"\
      #Display 10 colors per lines
      if [ $((($color + 1) % 10)) == 0 ] ; then
        echo #New line
      fi
    done
    echo #New line
  done
}
