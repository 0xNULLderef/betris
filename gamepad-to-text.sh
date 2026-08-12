#!/usr/bin/env bash

# Copyright 2026, NULLderef
# SPDX-License-Identifier: MIT

# proudly coded without any LLMs :3
# some reference taken from https://gitlab.freedesktop.org/libevdev/libevdev/
# as reading kernel docs is something i didn't feel like doing.

# `sizeof(struct input_event)` in '/usr/include/linux/linux/input.h'
INPUT_EVENT_SIZE=24

process() {
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
    # solution: use hexdump (womp womp fork) as it uses a bigger bufsize
    #           on my system it's 4096 but yours may vary.
    #           this technically isn't correct *either*, because it skips an
    #           EV_SYN event but we don't care about it sooooo ;3c
    readarray buffer < <(hexdump -v -n $INPUT_EVENT_SIZE -e '1/1 "%u\n"' <&3)

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
 
