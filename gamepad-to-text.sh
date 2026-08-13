#!/usr/bin/env bash

# Copyright 2026, NULLderef
# SPDX-License-Identifier: MIT

# proudly coded without any LLMs :3
# some reference taken from https://gitlab.freedesktop.org/libevdev/libevdev/
# as reading kernel docs is something i didn't feel like doing.

# if missing, substrings will split on utf-8 bytes. ask me how i know.
LC_ALL=C

# `sizeof(struct input_event)` in '/usr/include/linux/linux/input.h'
INPUT_EVENT_SIZE=24

# usage: read-buffer buffer size < source
# buffer has to be a declared array variable
#
read-buffer() {
  local remaining chunk size
  # avoid cricular nameref by _ prefix, i don't understand nameref well x3
  local -n _buffer=$1
  # clear buffer!
  _buffer=()

  # read loop inspired by https://github.com/bahamas10/bash-md5/blob/ce1e4d45760f4b7e5ec35ae52527c22aae877271/md5#L123
  for ((remaining = $2; remaining > 0; remaining -= size)); do
    IFS= read -r -d '' -n "$remaining" chunk
    local code=$?
    size=${#chunk}

    for ((i = 0; i < size; i++)); do
      local c=${chunk:i:1}
      printf -v c '%d' "'$c"
      _buffer+=("$c")
    done

    if ((size != remaining)); then
      _buffer+=(0)
      ((size++))
    fi

    # should never happen if the interface holds
    if ((code != 0)); then
     echo -e "read failed short (code = $code)\nbuffer = ${_buffer[*]}" >&2
     # bail because this *really* shouldn't happen
     exit 1
    fi
  done
}

process() {
  local -a buffer
  local event_type event_code event_value
  
  # open file. never closed because of looping in `while true`.
  # the os can handle it ;3
  exec 3< "$1"

  while true; do
    # read entire buffer as decimal bytes into the `buffer` array
    # 
    # problem: the `read` builtin does unbuffered (1 byte) reads on pipes
    #          and file descriptors, and the evdev driver's files throw EINVAL
    #          on reads smaller than an event size
    # 
    # solution: use dd (womp womp fork) as it allows to specify a block size
    read-buffer buffer $INPUT_EVENT_SIZE < <(dd bs=$INPUT_EVENT_SIZE count=1 status=none <&3)

    # type: u16 @ 16-17
    event_type=$((buffer[16] | buffer[17] << 8))
    # code: u16 @ 18-19
    event_code=$((buffer[18] | buffer[19] << 8))
    # value: s32 @ 20-23
    # read as unsigned first
    event_value=$((buffer[20] | buffer[21] << 8 | buffer[22] << 16 | buffer[23] << 24))
    # handle sign bit - s32 two's complement
    if ((event_value & 0x80000000)); then
      event_value=$((event_value - 0x100000000))
    fi

    if ((event_value == 0)); then
      continue
    fi

    case $event_type in
      1) # EV_KEY - buttons
        case $event_code in
          304) # A
            echo q
            ;;
          305) # B
            echo e
            ;;
        esac
        ;;
      3) # EV_ABS - dpad (and joysticks but idc)
        case $event_code in
          16) # horizontal
            if ((event_value == -1)); then
              echo a
            else
              echo d
            fi
            ;;
          17) # vertical
            if ((event_value == -1)); then
              echo w
            else
              echo s
            fi
            ;;
        esac
        ;;
    esac
  done
}

main() {
  if [ $# -ne 1 ]; then
    cat >&2 <<EOF
Bash* gamepad-to-text
   (*mostly)
   
usage: $0 file

potential files to try
EOF

    for f in /dev/input/by-id/*-event-joystick; do
      echo "  $f" >&2
    done

    exit 2
  fi

  process "$1"
}

main "$@"

