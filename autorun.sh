#!/bin/sh

run () {
  if ! pgrep $1 ; then
    "$@" &
  fi
}

run "picom"
run "redshift" -b 0.8 -l 18:41
run "bash" -c "input-remapper-control --command stop-all && input-remapper-control --command autoload"
run "discord"
run "qbittorrent"
run "copyq"
run "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
run "syncthingtray"
