#!/bin/sh
# volume : clic = couper / remettre le son, molette = +/- 3 %.
# volume_change ne part pas quand on coupe le son : on relit donc l etat a chaque fois.

case "$SENDER" in
  mouse.clicked)
    osascript -e 'set volume output muted not (output muted of (get volume settings))'
    ;;
  mouse.scrolled)
    step=3
    [ "${SCROLL_DELTA:-0}" -lt 0 ] && step=-3
    osascript -e "set volume output volume ((output volume of (get volume settings)) + $step)"
    ;;
esac

# « 42 false » ; volume « missing value » sur certaines sorties (hdmi...)
# le decoupage en mots est voulu : il separe volume et etat muet
# shellcheck disable=SC2046
set -- $(osascript -e 'set s to get volume settings' \
  -e 'return (output volume of s as text) & " " & (output muted of s as text)')
vol="$1"
muted="$2"

case "$vol" in
  '' | *[!0-9]*) sketchybar --set "$NAME" icon=󰕾 label="--"; exit 0 ;;
esac

if [ "$muted" = true ] || [ "$vol" -eq 0 ]; then
  icon=󰝟
elif [ "$vol" -lt 10 ]; then
  icon=󰕿
elif [ "$vol" -lt 60 ]; then
  icon=󰖀
else
  icon=󰕾
fi

sketchybar --set "$NAME" icon="$icon" label="${vol}%"
