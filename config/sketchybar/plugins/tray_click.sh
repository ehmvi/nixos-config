#!/bin/sh
# clic sur un alias du tray : sketchybar ne le transmet pas a l icone d origine.
# tray_click.js fait apparaitre la barre de menus masquee et clique la vraie icone
# (permission « accessibilite » pour sketchybar). $NAME est le nom de l alias.
#
# verrou : si la barre n est pas encore sortie, le clic simule retomberait sur
# sketchybar et relancerait ce script en boucle.
lock="${TMPDIR:-/tmp}/sketchybar-tray-click"
mkdir "$lock" 2>/dev/null || exit 0
trap 'sleep 1; rmdir "$lock"' EXIT
osascript -l JavaScript "$(dirname "$0")/tray_click.js" "$NAME"
