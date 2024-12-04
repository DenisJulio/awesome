#!/bin/sh

run () {
  if ! pgrep $1 ; then
    "$@" &
  fi
}

run "ulauncher" --hide-window --no-window-shadow
run "redshift" -b 0.8 -l 18:41
