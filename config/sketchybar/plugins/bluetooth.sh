#!/bin/sh
# icone bluetooth seule (comme label-show = false dans config/wayle/config-navi.toml).
state="$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo 0)"
if [ "$state" = "1" ]; then
  icon=󰂯
else
  icon=󰂲
fi
sketchybar --set "$NAME" icon="$icon"
