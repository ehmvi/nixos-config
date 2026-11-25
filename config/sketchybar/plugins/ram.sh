#!/bin/sh
# ram utilisee (active + wired + compressee) en pourcentage, comme le moniteur d'activite.
total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
[ "$total_bytes" -le 0 ] && exit 0

pct="$(vm_stat | awk -v total="$total_bytes" '
  /page size of/ {
    for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/) { ps = $i; break }
  }
  /^Pages active:/ { gsub(/\./, "", $3); active = $3 }
  /^Pages wired down:/ { gsub(/\./, "", $4); wired = $4 }
  /^Pages occupied by compressor:/ { gsub(/\./, "", $5); comp = $5 }
  END {
    if (ps <= 0) ps = 16384
    used = (active + wired + comp) * ps
    v = int((used / total) * 100 + 0.5)
    if (v > 100) v = 100
    printf "%d", v
  }
')"
sketchybar --set "$NAME" icon=󰍛 label="${pct}%"
