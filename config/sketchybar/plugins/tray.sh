#!/bin/sh
# tray : recopie les icones de la barre de menus macos (masquee) dans sketchybar,
# comme le systray de wayle sur navi et games. sketchybar ne sait que les capturer
# (alias) : il faut la permission « enregistrement de l ecran ». lance au chargement,
# toutes les 10 s et au reveil, pour suivre les apps qui demarrent ou quittent.
#
# depuis macos 26, toutes les icones appartiennent a « Control Centre », et celles des
# apps tierces s appellent souvent toutes « Item-0 ». on garde donc le nom complet de la
# requete, rang compris (« Control Centre,Item-0(7) », rang 1 = la plus a droite) :
# sketchybar sait retrouver l icone par ce rang. un alias porte le nom de sa cible ;
# nos autres items n ont pas de virgule, c est ce qui les distingue.

dir="$(dirname "$0")"

# ecartees : heure, batterie et volume sont deja des items de la barre
skip='^(Control Cent(re|er),(Clock|Battery|Sound)$|(Spotlight|Siri|TextInputMenuAgent|WindowManager|NotificationCenter|sketchybar),)'

# sans permission, la requete repond un message et pas du json : on ne touche a rien
raw="$(sketchybar --query default_menu_items)"
printf '%s' "$raw" | jq -e 'type == "array"' >/dev/null 2>&1 || exit 0
wanted="$(printf '%s' "$raw" | jq -r '.[]' | awk -v skip="$skip" '
  { base = $0; sub(/\([0-9]+\)$/, "", base) }
  base !~ skip && !seen[$0]++')"
current="$(sketchybar --query bar | jq -r '.items[]' | grep ',')"

changed=0

# icones disparues (ou dont le rang a bouge) : on retire l alias
while IFS= read -r item; do
  [ -z "$item" ] && continue
  printf '%s\n' "$wanted" | grep -Fxq -- "$item" && continue
  sketchybar --remove "$item"
  changed=1
done <<LIST
$current
LIST

# nouvelles icones : marges negatives pour rogner le vide que macos met autour de
# chaque icone, et teinte unie (TRAY_COLOR, l accent du theme passe par sketchybarrc)
while IFS= read -r item; do
  [ -z "$item" ] && continue
  printf '%s\n' "$current" | grep -Fxq -- "$item" && continue
  sketchybar --add alias "$item" right \
    --set "$item" padding_left=-5 padding_right=-5 alias.update_freq=2 \
      alias.color="${TRAY_COLOR:-0xffffffff}" \
      click_script="$dir/tray_click.sh"
  changed=1
done <<LIST
$wanted
LIST

# remet tout dans l ordre de la vraie barre, entre l heure et la batterie
[ "$changed" = 1 ] || exit 0
set --
while IFS= read -r item; do
  [ -n "$item" ] && set -- "$@" --move "$item" before battery
done <<LIST
$wanted
LIST
[ $# -gt 0 ] && sketchybar "$@"
