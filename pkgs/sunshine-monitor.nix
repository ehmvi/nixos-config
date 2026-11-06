# script prep de sunshine (modules/programs/sunshine.nix) : passe l'ecran a la
# resolution du client moonlight, puis remet le mode et redemarre sunshine.
# hyprland et systemd viennent du host : les memes binaires que la session.
{
  lib,
  writeShellScript,
  hyprland,
  systemd,
  coreutils,
  jq,
}:

# le 27 pouces est en 2560x1440@360, echelle 1
# (config/hypr/hyprland.lua). l'ecran du mac est en 1920x1080 : le
# stream 1440p y etait reduit, l'interface petite et floue. pendant le
# stream, on passe le panneau a la resolution demandee par moonlight,
# si l'edid l'a (1920x1080 existe jusqu'a 360 hz). l'echelle reste 1 :
# 1.333 rendrait floues les fenetres xwayland, dont wezterm sur games.
# sunshine donne la resolution du client dans SUNSHINE_CLIENT_WIDTH
# et SUNSHINE_CLIENT_HEIGHT.
# hl.monitor reprend la regle du meme nom et n'ecrit que les champs
# donnes. ici le nom est vide, donc output = "". un nom DP-1 ferait
# une regle neuve, mode prefere et 60 hz.
# le service sunshine a un path vide. hyprland ne lui donne pas
# forcement HYPRLAND_INSTANCE_SIGNATURE. le script trouve le socket.
# l'undo est hyprctl reload : il rejoue hyprland.lua, donc le mode
# 2560x1440@360 et le dofile de matugen-colors.lua.
writeShellScript "sunshine-monitor" ''
  set -euo pipefail

  export PATH=${
    lib.makeBinPath [
      hyprland
      systemd
      coreutils
      jq
    ]
  }

  runtime="''${XDG_RUNTIME_DIR:-}"
  if [ -z "$runtime" ]; then
    echo "sunshine-monitor: XDG_RUNTIME_DIR absent" >&2
    exit 1
  fi

  sig="''${HYPRLAND_INSTANCE_SIGNATURE:-}"
  if [ -z "$sig" ] || [ ! -S "$runtime/hypr/$sig/.socket.sock" ]; then
    sig=""
    for sock in "$runtime"/hypr/*/.socket.sock; do
      if [ -S "$sock" ]; then
        inst="''${sock%/.socket.sock}"
        sig="''${inst##*/}"
        break
      fi
    done
  fi

  if [ -z "$sig" ]; then
    echo "sunshine-monitor: pas de socket hyprland" >&2
    exit 1
  fi

  export HYPRLAND_INSTANCE_SIGNATURE="$sig"
  export XDG_RUNTIME_DIR="$runtime"

  # la substitution retire le saut de ligne de println. "ok" est la
  # reponse exacte de eval et de reload.
  hypr() {
    reply=$(hyprctl "$@" 2>&1 || true)
    if [ "$reply" != "ok" ]; then
      echo "sunshine-monitor: $reply" >&2
      exit 1
    fi
  }

  case "''${1:-}" in
    apply)
      res="''${SUNSHINE_CLIENT_WIDTH:-}x''${SUNSHINE_CLIENT_HEIGHT:-}"
      # mode actuel ou absent de l'edid (16:10 du mac) : on ne touche
      # a rien. sinon le rafraichissement le plus haut de ce mode.
      mode=$(hyprctl -j monitors all | jq -r --arg res "$res@" '
        .[0] | select((.width | tostring) + "x" + (.height | tostring) + "@" != $res)
        | [.availableModes[] | select(startswith($res)) | rtrimstr("Hz")]
        | sort_by(ltrimstr($res) | tonumber) | last // empty')
      if [ -z "$mode" ]; then
        echo "sunshine-monitor: $res, mode inchange"
        exit 0
      fi
      hypr eval "hl.monitor({ output = \"\", mode = \"$mode\" })"
      ;;
    restore)
      hypr reload
      # sunshine perd de la vram a chaque session (capture wlroots) :
      # 8 sessions en 3 h ont rempli 11 go sur 12, et wezterm plantait
      # en ouvrant une fenetre. --no-block rend la main tout de suite,
      # l'undo se termine avant que systemd arrete sunshine.
      systemctl --user restart --no-block sunshine.service
      ;;
    *)
      echo "sunshine-monitor: apply ou restore" >&2
      exit 1
      ;;
  esac
''
