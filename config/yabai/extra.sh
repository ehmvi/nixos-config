# chargement de la scripting addition au demarrage et si le dock redemarre.
# chemin complet du store requis par /etc/sudoers.d/yabai et secure_path.
# apres une mise a jour de l'osax, le premier appel installe et redemarre le dock,
# le second injecte reellement la charge utile.
yabai -m signal --add event=dock_did_restart action="sudo -n @yabai@ --load-sa"
sudo -n @yabai@ --load-sa || true
sleep 1
sudo -n @yabai@ --load-sa || true
sleep 0.5

# garantit 10 espaces sur l'ecran principal pour que mod+1..0 et les regles
# d'applis aient toujours une cible. s'arrete proprement si la sa n'est pas chargee.
space_count=$(yabai -m query --spaces --display 1 2>/dev/null | jq 'length' 2>/dev/null || echo 0)
if [ "$space_count" -gt 0 ]; then
  while [ "$space_count" -lt 10 ]; do
    yabai -m space --create 1 >/dev/null 2>&1 || break
    space_count=$((space_count + 1))
  done
fi
sketchybar --trigger yabai_windows >/dev/null 2>&1 || true

# synchro immediate de la barre des espaces dans sketchybar
yabai -m signal --add event=space_changed action="sketchybar --trigger space_change"
yabai -m signal --add event=window_created action="sketchybar --trigger yabai_windows"
yabai -m signal --add event=window_destroyed action="sketchybar --trigger yabai_windows"
yabai -m signal --add event=window_moved action="sketchybar --trigger yabai_windows"
yabai -m signal --add event=window_minimized action="sketchybar --trigger yabai_windows"
yabai -m signal --add event=window_deminimized action="sketchybar --trigger yabai_windows"

# plan d'espaces aligne sur config/hypr/hyprland.lua (sans ^ = silencieux, sans suivre)
# 1 : grok bot et timon
yabai -m rule --add app="^(Grok Bot|grok-bot)$" space=1
yabai -m rule --add app="^Timon$" space=1

# 2 : t3 code
yabai -m rule --add app="^T3 Code.*$" space=2

# 4 : navigateurs
yabai -m rule --add app="^(Brave Browser|Zen|Zen Browser|Ardia|Mullvad Browser|Ladybird|Safari)$" space=4

# 5 : social et traitement micro
yabai -m rule --add app="^(Vesktop|Equibop|Signal|FSA|fsa|MSGA|msga|Monal)$" space=5

# scratchpad : terminal deroulant kitty (lance au premier lalt+s)
yabai -m rule --add app="^kitty$" title="^dropterm$" scratchpad=term grid=10:10:1:1:8:5

# fenetres utilitaires macos en flottant
yabai -m rule --add app="^(System Settings|System Information|Calculator|Archive Utility|Activity Monitor|Bitwarden|Ente Auth|AlDente|Raycast|Software Update|Installer)$" manage=off
yabai -m rule --add app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off

yabai -m rule --apply
