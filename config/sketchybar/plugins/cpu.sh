#!/bin/sh
# charge cpu globale en pourcentage (normalisee sur le nombre de coeurs).
cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
pct="$(ps -A -o %cpu= | awk -v c="$cores" '{ s += $1 } END { v = int(s / c + 0.5); if (v > 100) v = 100; printf "%d", v }')"
sketchybar --set "$NAME" icon=󰓅 label="${pct}%"
