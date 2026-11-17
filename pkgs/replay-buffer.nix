# replay-buffer : relecture des 30 dernieres secondes avec gpu-screen-recorder
# (encodage gpu), pilotee par deux binds de hyprland.lua (games seulement).
#   replay-buffer toggle : lance le tampon, ou l'arrete (SIGINT, rien n'est sauve)
#   replay-buffer save   : SIGUSR1, ecrit les 30 s dans ~/Videos/Replays
# jamais lance au demarrage : un encodage gpu continu (nvenc ou vulkan) garde tres
# probablement la 4070 hors de p8 (nvdec dans mpv la passait de p8 a p2,
# 18 w de plus, voir hosts/navi/default.nix). le tampon ne tourne donc que
# quand on l'allume. mesure : `nvidia-smi -q -d PERFORMANCE` pendant qu'il tourne.
# notify-send (libnotify) plutot que gdbus : les deux sont deja dans la
# cloture de games, notify-send se lit mieux et gere seul l'echappement.
{
  writeShellApplication,
  gpu-screen-recorder,
  libnotify,
  coreutils,
  gnugrep,
}:

let
  # lance par gpu-screen-recorder (-sc) une fois le fichier ecrit, avec le
  # chemin en $1. la notification arrive donc quand la video existe, pas
  # au moment du signal.
  saved = writeShellApplication {
    name = "replay-buffer-saved";
    runtimeInputs = [
      libnotify
      coreutils
    ];
    text = ''
      notify-send -a replay-buffer -i media-record "Replay sauvé" "$(basename "$1")"
    '';
  };
in
writeShellApplication {
  name = "replay-buffer";
  runtimeInputs = [
    gpu-screen-recorder
    libnotify
    coreutils
    gnugrep
  ];
  text = ''
    dir="$HOME/Videos/Replays"
    runtime="''${XDG_RUNTIME_DIR:-/tmp}"
    pidfile="$runtime/replay-buffer.pid"
    log="$runtime/replay-buffer.log"

    notify() {
      notify-send -a replay-buffer -i media-record "$@"
    }

    # pid du tampon s'il tourne. comm verifie que le pid n'a pas ete
    # repris par un autre programme (comm est tronque a 15 caracteres).
    running_pid() {
      local pid
      pid=$(cat "$pidfile" 2>/dev/null) || return 1
      if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        return 1
      fi
      [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = "gpu-screen-reco" ] || return 1
      echo "$pid"
    }

    start() {
      mkdir -p "$dir"
      # h264 = nvenc. gsr le retire de --info quand le pilote ne suit pas
      # l'api nvenc de ffmpeg : le 595 donne 13.0, le ffmpeg 9 de nixpkgs
      # demande 13.1. on passe alors par vulkan video, que gsr dit
      # experimental, mais teste ici avec ffmpeg (h264_vulkan).
      # --info prend environ 0,3 s.
      local codec=h264
      local info
      info=$(gpu-screen-recorder --info 2>/dev/null || true)
      if ! grep -qx h264 <<<"$info"; then
        codec=h264_vulkan
      fi
      # -w screen : premier ecran (games n'en a qu'un). h264 et aac pour
      # qu'un clip passe partout (discord, navigateurs). cbr 40 mbit/s :
      # ram previsible, environ 150 mo pour 30 s en 1440p60.
      # -v no : pas de ligne de fps par seconde dans le journal.
      gpu-screen-recorder \
        -w screen -f 60 -r 30 -replay-storage ram \
        -c mp4 -k "$codec" -bm cbr -q 40000 \
        -a default_output -ac aac \
        -encoder gpu -v no \
        -sc ${saved}/bin/replay-buffer-saved \
        -o "$dir" >"$log" 2>&1 &
      echo $! >"$pidfile"
      # une erreur de capture ou d'encodeur fait sortir gsr tout de suite
      sleep 1
      if running_pid >/dev/null; then
        notify "Replay en marche ($codec)" "30 s en mémoire. Super+F10 pour sauver, Super+F9 pour arrêter."
      else
        rm -f "$pidfile"
        notify -u critical "Replay : échec du lancement" "$(tail -n 3 "$log")"
        exit 1
      fi
    }

    stop() {
      local pid=$1
      # en mode replay, SIGINT arrete sans rien sauver
      kill -INT "$pid"
      for _ in $(seq 50); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
      done
      rm -f "$pidfile"
      notify "Replay arrêté" "Le tampon est vidé."
    }

    case "''${1:-}" in
      toggle)
        if pid=$(running_pid); then
          stop "$pid"
        else
          start
        fi
        ;;
      save)
        if pid=$(running_pid); then
          # la notification vient de replay-buffer-saved, une fois le fichier ecrit
          kill -USR1 "$pid"
        else
          notify "Replay éteint" "Super+F9 pour le lancer."
          exit 1
        fi
        ;;
      *)
        echo "usage: replay-buffer toggle|save" >&2
        exit 1
        ;;
    esac
  '';
}
