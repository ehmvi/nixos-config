# power-menu : menu rofi de super+m (verrouiller, veille, deconnexion,
# redemarrer, eteindre). echap ou un choix vide ne fait rien.
# deconnexion par uwsm stop : la session uwsm se termine proprement et sddm
# relance son greeter. hyprctl exit seulement si uwsm est absent.
{
  writeShellApplication,
  rofi,
}:

writeShellApplication {
  name = "power-menu";
  runtimeInputs = [ rofi ];
  text = ''
    choice=$(printf '%s\n' lock suspend logout reboot shutdown |
      rofi -dmenu -no-custom -p power) || exit 0

    case "$choice" in
      lock) loginctl lock-session ;;
      suspend) systemctl suspend ;;
      logout)
        if command -v uwsm > /dev/null; then
          uwsm stop
        else
          hyprctl dispatch 'hl.dsp.exit()'
        fi
        ;;
      reboot) systemctl reboot ;;
      shutdown) systemctl poweroff ;;
    esac
  '';
}
