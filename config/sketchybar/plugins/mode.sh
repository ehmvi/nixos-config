#!/bin/sh
# indicateur de mode skhd : visible uniquement hors du mode default (ex. resize).
if [ -n "$MODE" ] && [ "$MODE" != "default" ]; then
  upper="$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')"
  sketchybar --set "$NAME" drawing=on label="$upper"
else
  sketchybar --set "$NAME" drawing=off
fi
