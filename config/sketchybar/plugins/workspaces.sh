#!/bin/sh
# espaces yabai 1..10 : affiche 1..3 en permanence et 4..10 si actif ou occupe
# (comme min-workspace-count = 3 dans config/wayle/config-navi.toml).
# les couleurs passent en variables d'environnement depuis sketchybarrc.

ACCENT="${BAR_ACCENT:-0xff85d6c1}"
BASE="${BAR_BASE:-0xff0e1513}"
TEXT="${BAR_TEXT:-0xffdee4e0}"
DIM="${BAR_DIM:-0xff5d6763}"

spaces_json="$(yabai -m query --spaces 2>/dev/null)"

# si yabai ne repond pas encore (avant la sa ou au demarrage), garde 1..3 visibles
if [ -z "$spaces_json" ]; then
  sketchybar \
    --set space.1 drawing=on icon.color="$BASE" icon.background.drawing=on icon.background.color="$ACCENT" \
    --set space.2 drawing=on icon.color="$DIM" icon.background.drawing=off \
    --set space.3 drawing=on icon.color="$DIM" icon.background.drawing=off \
    --set space.4 drawing=off --set space.5 drawing=off --set space.6 drawing=off \
    --set space.7 drawing=off --set space.8 drawing=off --set space.9 drawing=off \
    --set space.10 drawing=off
  exit 0
fi

# extrait « index focus count » par espace en un seul appel jq
parsed="$(printf '%s' "$spaces_json" | jq -r '.[] | "\(.index) \(if ."has-focus" then 1 else 0 end) \(.windows | length)"')"

set --
i=1
while [ "$i" -le 10 ]; do
  line="$(printf '%s\n' "$parsed" | awk -v idx="$i" '$1 == idx { print $2, $3; exit }')"
  focused=0
  wins=0
  if [ -n "$line" ]; then
    focused="${line%% *}"
    wins="${line#* }"
  fi

  if [ "$focused" -eq 1 ]; then
    set -- "$@" --set "space.$i" drawing=on icon.color="$BASE" icon.background.drawing=on icon.background.color="$ACCENT"
  elif [ "$wins" -gt 0 ]; then
    set -- "$@" --set "space.$i" drawing=on icon.color="$TEXT" icon.background.drawing=off
  elif [ "$i" -le 3 ]; then
    set -- "$@" --set "space.$i" drawing=on icon.color="$DIM" icon.background.drawing=off
  else
    set -- "$@" --set "space.$i" drawing=off icon.background.drawing=off
  fi
  i=$((i + 1))
done

sketchybar "$@"
