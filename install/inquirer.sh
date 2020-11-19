#!/usr/bin/env bash

#======== Based on (then updated) https://raw.githubusercontent.com/tanhauhau/Inquirer.sh/master/dist/inquirer.sh ========

# License from: https://github.com/kahkhang/Inquirer.sh/blob/master/LICENSE

# The MIT License (MIT)

# Copyright (c) 2017

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# store the current set options
OLD_SET=$-
set -e

arrow="$(echo -e '\xe2\x9d\xaf')"
checked="$(echo -e '\xe2\x97\x89')"
unchecked="$(echo -e '\xe2\x97\xaf')"

black="$(tput setaf 0)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
blue="$(tput setaf 4)"
magenta="$(tput setaf 5)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
bold="$(tput bold)"
normal="$(tput sgr0)"
dim=$'\e[2m'

print() {
  echo "$1"
  tput el
}

join() {
  local IFS=$'\n'
  local _join_list
  eval _join_list=( '"${'${1}'[@]}"' )
  local first=true
  for item in ${_join_list[@]}; do
    if [ "$first" = true ]; then
      printf "%s" "$item"
      first=false
    else
      printf "${2-, }%s" "$item"
    fi
  done
}

function gen_env_from_options() {
  local IFS=$'\n'
  local _indices
  local _env_names
  local _checkbox_selected
  eval _indices=( '"${'${1}'[@]}"' )
  eval _env_names=( '"${'${2}'[@]}"' )

  for i in $(gen_index ${#_env_names[@]}); do
    _checkbox_selected[$i]=false
  done

  for i in ${_indices[@]}; do
    _checkbox_selected[$i]=true
  done

  for i in $(gen_index ${#_env_names[@]}); do
    printf "%s=%s\n" "${_env_names[$i]}" "${_checkbox_selected[$i]}"
  done
}

on_default() {
  true;
}

on_keypress() {
  local OLD_IFS
  local IFS
  local key
  OLD_IFS=$IFS
  local on_up=${1:-on_default}
  local on_down=${2:-on_default}
  local on_space=${3:-on_default}
  local on_enter=${4:-on_default}
  local on_left=${5:-on_default}
  local on_right=${6:-on_default}
  local on_ascii=${7:-on_default}
  local on_backspace=${8:-on_default}
  _break_keypress=false
  while IFS="" read -rsn1 key; do
      case "$key" in
      $'\x1b')
          read -rsn1 key
          if [[ "$key" == "[" ]]; then
              read -rsn1 key
              case "$key" in
              'A') eval $on_up;;
              'B') eval $on_down;;
              'D') eval $on_left;;
              'C') eval $on_right;;
              esac
          fi
          ;;
      ' ') eval $on_space ' ';;
      [a-z0-9A-Z\!\#\$\&\+\,\-\.\/\;\=\?\@\[\]\^\_\{\}\~]) eval $on_ascii $key;;
      $'\x7f') eval $on_backspace $key;;
      '') eval $on_enter $key;;
      esac
      if [ $_break_keypress = true ]; then
        break
      fi
  done
  IFS=$OLD_IFS
}

gen_index() {
  local k=$1
  local l=0
  if [ $k -gt 0 ]; then
    for l in $(seq $k)
    do
       echo "$l-1" | bc
    done
  fi
}

cleanup() {
  # Reset character attributes, make cursor visible, and restore
  # previous screen contents (if possible).
  tput sgr0
  tput cnorm
  stty echo

  # Restore `set e` option to its orignal value
  if [[ $OLD_SET =~ e ]]
  then set -e
  else set +e
  fi
}

control_c() {
  cleanup
  exit $?
}

select_indices() {
  local _select_list
  local _select_indices
  local _select_selected=()
  eval _select_list=( '"${'${1}'[@]}"' )
  eval _select_indices=( '"${'${2}'[@]}"' )
  local _select_var_name=$3
  eval $_select_var_name\=\(\)
  for i in $(gen_index ${#_select_indices[@]}); do
    eval $_select_var_name\+\=\(\""${_select_list[${_select_indices[$i]}]}"\"\)
  done
}




on_checkbox_input_up() {
  remove_checkbox_instructions
  tput cub "$(tput cols)"

  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    printf " ${green}${checked}${normal} ${_checkbox_list[$_current_index]} ${normal}"
  else
    printf " ${unchecked} ${_checkbox_list[$_current_index]} ${normal}"
  fi
  tput el

  if [ $_current_index = 0 ]; then
    _current_index=$((${#_checkbox_list[@]}-1))
    tput cud $((${#_checkbox_list[@]}-1))
    tput cub "$(tput cols)"
  else
    _current_index=$((_current_index-1))

    tput cuu1
    tput cub "$(tput cols)"
    tput el
  fi

  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    printf "${cyan}${arrow}${green}${checked}${normal} ${_checkbox_list[$_current_index]} ${normal}"
  else
    printf "${cyan}${arrow}${normal}${unchecked} ${_checkbox_list[$_current_index]} ${normal}"
  fi
}

on_checkbox_input_down() {
  remove_checkbox_instructions
  tput cub "$(tput cols)"

  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    printf " ${green}${checked}${normal} ${_checkbox_list[$_current_index]} ${normal}"
  else
    printf " ${unchecked} ${_checkbox_list[$_current_index]} ${normal}"
  fi

  tput el

  if [ $_current_index = $((${#_checkbox_list[@]}-1)) ]; then
    _current_index=0
    tput cuu $((${#_checkbox_list[@]}-1))
    tput cub "$(tput cols)"
  else
    _current_index=$((_current_index+1))
    tput cud1
    tput cub "$(tput cols)"
    tput el
  fi

  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    printf "${cyan}${arrow}${green}${checked}${normal} ${_checkbox_list[$_current_index]} ${normal}"
  else
    printf "${cyan}${arrow}${normal}${unchecked} ${_checkbox_list[$_current_index]} ${normal}"
  fi
}

on_checkbox_input_enter() {
  local OLD_IFS
  OLD_IFS=$IFS
  _checkbox_selected_indices=()
  _checkbox_selected_options=()
  IFS=$'\n'

  for i in $(gen_index ${#_checkbox_list[@]}); do
    if [ "${_checkbox_selected[$i]}" = true ]; then
      _checkbox_selected_indices+=($i)
      _checkbox_selected_options+=("${_checkbox_list[$i]}")
    fi
  done

  tput cud $((${#_checkbox_list[@]}-${_current_index}))
  tput cub "$(tput cols)"

  for i in $(seq $((${#_checkbox_list[@]}+1))); do
    tput el1
    tput el
    tput cuu1
  done
  tput cub "$(tput cols)"

  tput cuf $((${#prompt}+3))
  printf "${cyan}$(join _checkbox_selected_options)${normal}"
  tput el

  tput cud1
  tput cub "$(tput cols)"
  tput el

  _break_keypress=true
  IFS=$OLD_IFS
}

on_checkbox_input_space() {
  remove_checkbox_instructions
  tput cub "$(tput cols)"
  tput el
  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    _checkbox_selected[$_current_index]=false
  else
    _checkbox_selected[$_current_index]=true
  fi

  if [ "${_checkbox_selected[$_current_index]}" = true ]; then
    printf "${cyan}${arrow}${green}${checked}${normal} ${_checkbox_list[$_current_index]} ${normal}"
  else
    printf "${cyan}${arrow}${normal}${unchecked} ${_checkbox_list[$_current_index]} ${normal}"
  fi
}

remove_checkbox_instructions() {
  if [ $_first_keystroke = true ]; then
    tput cuu $((${_current_index}+1))
    tput cub "$(tput cols)"
    tput cuf $((${#prompt}+3))
    tput el
    tput cud $((${_current_index}+1))
    _first_keystroke=false
  fi
}

# for vim movements
on_checkbox_input_ascii() {
  local key=$1
  case $key in
    "j" ) on_checkbox_input_down;;
    "k" ) on_checkbox_input_up;;
  esac
}

_checkbox_input() {
  local i
  local j
  prompt=$1
  eval _checkbox_list=( '"${'${2}'[@]}"' )
  _current_index=0
  _first_keystroke=true

  trap control_c SIGINT EXIT

  stty -echo
  tput civis

  print "${normal}${green}?${normal} ${bold}${prompt}${normal} ${dim}(Press <space> to select, <enter> to finalize)${normal}"

  for i in $(gen_index ${#_checkbox_list[@]}); do
    _checkbox_selected[$i]=false
  done

  if [ -n "$3" ]; then
    eval _selected_indices=( '"${'${3}'[@]}"' )
    for i in ${_selected_indices[@]}; do
      _checkbox_selected[$i]=true
    done
  fi

  for i in $(gen_index ${#_checkbox_list[@]}); do
    tput cub "$(tput cols)"
    if [ $i = 0 ]; then
      if [ "${_checkbox_selected[$i]}" = true ]; then
        print "${cyan}${arrow}${green}${checked}${normal} ${_checkbox_list[$i]} ${normal}"
      else
        print "${cyan}${arrow}${normal}${unchecked} ${_checkbox_list[$i]} ${normal}"
      fi
    else
      if [ "${_checkbox_selected[$i]}" = true ]; then
        print " ${green}${checked}${normal} ${_checkbox_list[$i]} ${normal}"
      else
        print " ${unchecked} ${_checkbox_list[$i]} ${normal}"
      fi
    fi
    tput el
  done

  for j in $(gen_index ${#_checkbox_list[@]}); do
    tput cuu1
  done

  on_keypress on_checkbox_input_up on_checkbox_input_down on_checkbox_input_space on_checkbox_input_enter on_default on_default on_checkbox_input_ascii
}

checkbox_input() {
  _checkbox_input "$1" "$2"
  _checkbox_input_output_var_name=$3
  select_indices _checkbox_list _checkbox_selected_indices $_checkbox_input_output_var_name

  unset _checkbox_list
  unset _break_keypress
  unset _first_keystroke
  unset _current_index
  unset _checkbox_input_output_var_name
  unset _checkbox_selected_indices
  unset _checkbox_selected_options

  cleanup
}

checkbox_input_indices() {
  _checkbox_input "$1" "$2" "$3"
  _checkbox_input_output_var_name=$3

  eval $_checkbox_input_output_var_name\=\(\)
  for i in $(gen_index ${#_checkbox_selected_indices[@]}); do
    eval $_checkbox_input_output_var_name\+\=\(${_checkbox_selected_indices[$i]}\)
  done

  unset _checkbox_list
  unset _break_keypress
  unset _first_keystroke
  unset _current_index
  unset _checkbox_input_output_var_name
  unset _checkbox_selected_indices
  unset _checkbox_selected_options

  cleanup
}




on_list_input_up() {
  remove_list_instructions
  tput cub "$(tput cols)"

  printf "  ${_list_options[$_list_selected_index]}"
  tput el

  if [ $_list_selected_index = 0 ]; then
    _list_selected_index=$((${#_list_options[@]}-1))
    tput cud $((${#_list_options[@]}-1))
    tput cub "$(tput cols)"
  else
    _list_selected_index=$((_list_selected_index-1))

    tput cuu1
    tput cub "$(tput cols)"
    tput el
  fi

  printf "${cyan}${arrow} %s ${normal}" "${_list_options[$_list_selected_index]}"
}

on_list_input_down() {
  remove_list_instructions
  tput cub "$(tput cols)"

  printf "  ${_list_options[$_list_selected_index]}"
  tput el

  if [ $_list_selected_index = $((${#_list_options[@]}-1)) ]; then
    _list_selected_index=0
    tput cuu $((${#_list_options[@]}-1))
    tput cub "$(tput cols)"
  else
    _list_selected_index=$((_list_selected_index+1))
    tput cud1
    tput cub "$(tput cols)"
    tput el
  fi
  printf "${cyan}${arrow} %s ${normal}" "${_list_options[$_list_selected_index]}"
}

on_list_input_enter_space() {
  local OLD_IFS
  OLD_IFS=$IFS
  IFS=$'\n'

  tput cud $((${#_list_options[@]}-${_list_selected_index}))
  tput cub "$(tput cols)"

  for i in $(seq $((${#_list_options[@]}+1))); do
    tput el1
    tput el
    tput cuu1
  done
  tput cub "$(tput cols)"

  tput cuf $((${#prompt}+3))
  printf "${cyan}${_list_options[$_list_selected_index]}${normal}"
  tput el

  tput cud1
  tput cub "$(tput cols)"
  tput el

  _break_keypress=true
  IFS=$OLD_IFS
}

remove_list_instructions() {
  if [ $_first_keystroke = true ]; then
    tput cuu $((${_list_selected_index}+1))
    tput cub "$(tput cols)"
    tput cuf $((${#prompt}+3))
    tput el
    tput cud $((${_list_selected_index}+1))
    _first_keystroke=false
  fi
}

_list_input() {
  local i
  local j
  prompt=$1
  eval _list_options=( '"${'${2}'[@]}"' )

  _list_selected_index=0
  _first_keystroke=true

  trap control_c SIGINT EXIT

  stty -echo
  tput civis

  print "${normal}${green}?${normal} ${bold}${prompt}${normal} ${dim}(Use arrow keys)${normal}"

  for i in $(gen_index ${#_list_options[@]}); do
    tput cub "$(tput cols)"
    if [ $i = 0 ]; then
      print "${cyan}${arrow} ${_list_options[$i]} ${normal}"
    else
      print "  ${_list_options[$i]}"
    fi
    tput el
  done

  for j in $(gen_index ${#_list_options[@]}); do
    tput cuu1
  done

  on_keypress on_list_input_up on_list_input_down on_list_input_enter_space on_list_input_enter_space

}


list_input() {
  _list_input "$1" "$2"
  local var_name=$3
  eval $var_name=\'"${_list_options[$_list_selected_index]}"\'
  unset _list_selected_index
  unset _list_options
  unset _break_keypress
  unset _first_keystroke

  cleanup
}

list_input_index() {
  _list_input "$1" "$2"
  local var_name=$3
  eval $var_name=\'"$_list_selected_index"\'
  unset _list_selected_index
  unset _list_options
  unset _break_keypress
  unset _first_keystroke

  cleanup
}




on_text_input_left() {
  remove_regex_failed
  if [ $_current_pos -gt 0 ]; then
    tput cub1
    _current_pos=$(($_current_pos-1))
  fi
}

on_text_input_right() {
  remove_regex_failed
  if [ $_current_pos -lt ${#_text_input} ]; then
    tput cuf1
    _current_pos=$(($_current_pos+1))
  fi
}

on_text_input_enter() {
  remove_regex_failed

  if [[ "$_text_input" =~ $_text_input_regex && "$(eval $_text_input_validator "$_text_input")" = true ]]; then
    tput cub "$(tput cols)"
    tput cuf $((${#_read_prompt}-19))
    printf "${cyan}${_text_input}${normal}"
    tput el
    tput cud1
    tput cub "$(tput cols)"
    tput el
    eval $var_name=\'"${_text_input}"\'
    _break_keypress=true
  else
    _text_input_regex_failed=true
    tput civis
    tput cud1
    tput cub "$(tput cols)"
    tput el
    printf "${red}>>${normal} $_text_input_regex_failed_msg"
    tput cuu1
    tput cub "$(tput cols)"
    tput cuf $((${#_read_prompt}-19))
    tput el
    _text_input=""
    _current_pos=0
    tput cnorm
  fi
}

on_text_input_ascii() {
  remove_regex_failed
  local c=$1

  if [ "$c" = '' ]; then
    c=' '
  fi

  local rest="${_text_input:$_current_pos}"
  _text_input="${_text_input:0:$_current_pos}$c$rest"
  _current_pos=$(($_current_pos+1))

  tput civis
  printf "$c$rest"
  tput el
  if [ ${#rest} -gt 0 ]; then
    tput cub ${#rest}
  fi
  tput cnorm
}

on_text_input_backspace() {
  remove_regex_failed
  if [ $_current_pos -gt 0 ]; then
    local start="${_text_input:0:$(($_current_pos-1))}"
    local rest="${_text_input:$_current_pos}"
    _current_pos=$(($_current_pos-1))
    tput cub 1
    tput el
    tput sc
    printf "$rest"
    tput rc
    _text_input="$start$rest"
  fi
}

remove_regex_failed() {
  if [ $_text_input_regex_failed = true ]; then
    _text_input_regex_failed=false
    tput sc
    tput cud1
    tput el1
    tput el
    tput rc
  fi
}

text_input_default_validator() {
  echo true;
}

text_input() {
  local prompt=$1
  local var_name=$2
  local _text_input_regex="${3:-"\.+"}"
  local _text_input_regex_failed_msg=${4:-"Input validation failed"}
  local _text_input_validator=${5:-text_input_default_validator}
  local _read_prompt_start=$'\e[32m?\e[39m\e[1m'
  local _read_prompt_end=$'\e[22m'
  local _read_prompt="$( echo "$_read_prompt_start ${prompt} $_read_prompt_end")"
  local _current_pos=0
  local _text_input_regex_failed=false
  local _text_input=""
  printf "$_read_prompt"


  trap control_c SIGINT EXIT

  stty -echo
  tput cnorm

  on_keypress on_default on_default on_text_input_ascii on_text_input_enter on_text_input_left on_text_input_right on_text_input_ascii on_text_input_backspace
  eval $var_name=\'"${_text_input}"\'

  cleanup
}

# =============================================================

function menuFromCmd() {
	local mLOCALRESULT=$1
	local mRESULT=''
	read -r -a ARRAY <<< $3
	list_input "$2" ARRAY mRESULT
	eval $mLOCALRESULT="'$mRESULT'"
}

function menuFromArr() {
	local mLOCALRESULT=$1
	shift
	local PROMPT=$1
	shift
	local ARRAY=("$@")
	list_input "$PROMPT" ARRAY mRESULT
	eval $mLOCALRESULT="'$mRESULT'"
}

function multiFromArr() {
	local mLOCALRESULT=$1
	shift
	local PROMPT=$1
	shift
	local ARRAY=("$@")
	checkbox_input "$PROMPT" ARRAY mRESULT
	eval $mLOCALRESULT="'$mRESULT'"
}
