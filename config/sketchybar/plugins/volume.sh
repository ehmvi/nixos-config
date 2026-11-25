#!/bin/sh
[ "$SENDER" = "volume_change" ] || exit 0

case "$INFO" in
  0) icon=󰝟 ;;
  [0-9]) icon=󰕿 ;;
  [1-5][0-9]) icon=󰖀 ;;
  *) icon=󰕾 ;;
esac

sketchybar --set "$NAME" icon="$icon" label="${INFO}%"
