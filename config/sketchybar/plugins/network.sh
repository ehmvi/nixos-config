#!/bin/sh
# etat wifi sur en0. sur macos sequoia+, le ssid peut etre masque sans acces
# localisation : on se rabat alors sur "wi-fi" tant qu'une ip est active.
ip="$(ipconfig getifaddr en0 2>/dev/null)"
if [ -z "$ip" ]; then
  sketchybar --set "$NAME" icon=󰤮 label="off"
  exit 0
fi

ssid="$(networksetup -getairportnetwork en0 2>/dev/null | sed -n 's/^Current Wi-Fi Network: //p')"
case "$ssid" in
  '' | *'<redacted>'* | *'You are not associated'*)
    label="wi-fi"
    ;;
  *)
    # tronque pour ne jamais empieter sur l'encoche du 14 pouces
    if [ "${#ssid}" -gt 10 ]; then
      label="$(printf '%.9s' "$ssid")…"
    else
      label="$ssid"
    fi
    ;;
esac

sketchybar --set "$NAME" icon=󰤨 label="$label"
