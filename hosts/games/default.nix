# host: games
# desktop pc — gaming/multimedia
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  # le .desktop du paquet ouvre le programme dans un terminal quelconque,
  # sans classe, donc hyprland ne peut pas le placer. celui-ci passe devant
  # et ouvre wezterm avec une classe a lui, envoyee sur le workspace 6.
  monitorLauncher =
    {
      name,
      desktopName,
      class,
      command,
      icon,
    }:
    lib.hiPrio (
      pkgs.makeDesktopItem {
        inherit
          name
          desktopName
          icon
          ;
        exec = "wezterm start --always-new-process --class ${class} -- ${command}";
        terminal = false;
        categories = [
          "System"
          "Monitor"
        ];
        startupWMClass = class;
      }
    );

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
  sunshineMonitor = pkgs.writeShellScript "sunshine-monitor" ''
    set -euo pipefail

    export PATH=${
      lib.makeBinPath [
        config.programs.hyprland.package
        config.systemd.package
        pkgs.coreutils
        pkgs.jq
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
  '';
in

{
  imports = [
    ./hardware.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/health.nix
    ../../modules/hardware/nvidia-power.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/programs/cli.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/office.nix
    ../../modules/programs/apps.nix
    ../../modules/programs/spicetify.nix
    ./rgb-off.nix
  ];

  networking.hostName = "games";
  # shields-up reste enregistre par tailscaled. retirer le drapeau ne
  # le coupe pas : tailscaled-set ne lancerait plus `tailscale set`.
  # false le coupe a chaque demarrage.
  services.tailscale.extraSetFlags = [ "--shields-up=false" ];
  # reveil a distance depuis le pi (wake-on-lan)
  networking.interfaces.eno1.wakeOnLan.enable = true;
  # dual boot : la rtc reste en utc. côté windows, clé registre RealTimeIsUniversal = 1
  # git-lfs pour le depot de fichiers .blend, seulement sur games
  programs.git.lfs.enable = true;
  fyrr.wayle.configFile = ../../config/wayle/config-games.toml;

  boot.kernelModules = [ "nct6775" ];

  programs.coolercontrol.enable = true;

  # glm-4.7-flash en local. ollama 0.40.2 gere glm4moelite
  # (llama.cpp b11351). le paquet cuda manque dans cache.nixos.org et
  # compilerait llama.cpp avec nvcc. vulkan est deja en cache et passe
  # par le pilote nvidia deja installe. ecoute seulement sur localhost.
  # le quant q4_k_m (~19 go) se telecharge a la main, hors du store.
  # la rtx 4070 a 12 go : le surplus part en ram.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    openFirewall = false;
  };

  # stream du bureau vers le mac (moonlight), seulement via tailscale.
  # openFirewall reste faux : le module ouvrirait aussi le tcp 47990 et
  # l'udp 48002 et 48010, sur toutes les interfaces.
  # le paquet par defaut est celui du cache, construit sans cuda :
  # cudaSupport suit nixpkgs.config.cudaSupport, faux ici. ffmpeg
  # embarque essaie quand meme h264_nvenc. le journal dit qui a gagne.
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = false;
    # capture kms (drm), pas propre a nvidia. sous hyprland, sunshine
    # passe par wlroots et s'en passe. true donnerait cap_sys_admin,
    # presque root, a un binaire que n'importe quel utilisateur lance.
    capSysAdmin = false;
    # pc : l'ui web ne repond qu'a localhost. fermer le port 47990 dans
    # nixos ne suffit pas, ts-input accepte tout tailscale0. 100.64/10
    # est un lan pour sunshine, et son defaut accepte le lan.
    # ce reglage ecrit sunshine.conf dans le store, en lecture seule :
    # l'ui ne peut plus y sauver ses options. le mot de passe, les
    # certificats et les clients apparies vont ailleurs
    # (~/.config/sunshine/sunshine_state.json et credentials/).
    # global_prep_cmd : chaine json, le module n'accepte pas une liste.
    settings = {
      origin_web_ui_allowed = "pc";
      # sans capture fixee, sunshine essaie aussi le portail xdg au
      # demarrage. xdph ouvre alors "select what to share" et sunshine
      # attend un clic avant d'ecouter. en stream a distance, personne ne
      # clique : apres le redemarrage de fin de session, moonlight ne
      # pouvait plus se connecter. wlr capture tout l'ecran sans demander.
      capture = "wlr";
      # l'undo ne tourne qu'a la fin de la session moonlight, pas sur une
      # deconnexion. "quit app on host pc after ending stream" doit rester
      # cochee, sinon le mode 1440p ne revient pas, sunshine ne redemarre
      # pas et la vram s'accumule.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${sunshineMonitor} apply";
          undo = "${sunshineMonitor} restore";
        }
      ];
    };
  };

  # ffmpeg fait dlopen("libcuda.so.1") et dlopen("libnvidia-encode.so.1").
  # ces fichiers sont dans /run/opengl-driver/lib (hardware.nvidia les y
  # met deja). un service utilisateur n'herite pas le LD_LIBRARY_PATH de
  # la session, donc le chargement echoue. le chargeur renvoie -1, et
  # ffmpeg ecrit cela "Operation not permitted" : ce n'est pas le bac a
  # sable, ni /dev/nvidia*. cap_sys_admin reste faux, la capture hyprland
  # passe par wlroots. sans le cuda compile dans sunshine, l'image copie
  # gpu, ram, gpu, et l'encodage reste nvenc. cudaSupport = true
  # recompilerait le paquet avec nvcc (toolkit cuda, unfree, souvent
  # hors du cache) seulement pour eviter cette copie.
  # ne marche plus si capSysAdmin = true : le wrapper efface LD_LIBRARY_PATH.
  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH =
    "${pkgs.addDriverRunpath.driverLink}/lib";

  # le module limite sunshine a 5 demarrages en 500 s. chaque fin de
  # session moonlight le redemarre : des reconnexions rapprochees ont
  # atteint la limite (start-limit-hit), le service est reste arrete, et
  # un sunshine lance a la main a garde la vram de 5 sessions. 0 coupe la
  # limite. relancer avec systemctl --user restart sunshine, jamais le
  # binaire seul : hors du service, rien ne le redemarre apres un stream.
  systemd.user.services.sunshine.startLimitIntervalSec = lib.mkForce 0;

  # le module sunshine allume avahi (mkDefault) pour le reseau local.
  # le mac et le telephone joignent games par le nom ou l'ip tailscale.
  # cups est installe, mais il ne demande pas avahi : seul cups-browsed
  # s'en sert, pour trouver les imprimantes du lan. on le coupe avec.
  # sans le demon, sunshine ecrit "Failed to create client" et continue.
  services.avahi.enable = false;

  # ts-input accepte tout tailscale0 avant nixos-fw, donc cette liste ne
  # filtre pas aujourd'hui. on la garde : si cet accept disparait, seuls
  # ces ports passent, et seulement sur tailscale0. pas le 47990.
  # le vrai filtre, shields-up etant coupe, ce sont les acls tailscale.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      47984
      47989
      48010
    ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48000;
      }
    ];
  };

  system.stateVersion = "25.11";
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/egctl.nix { })
    # blender sans cuda : cudaSupport = true compile depuis les sources, sans cache binaire
    pkgs.blender
    # release linux officielle : le paquet nixpkgs exige la rom us a la compilation
    (pkgs.callPackage ../../pkgs/sm64coopdx.nix { })
    # decoupe video sans reencodage. nixpkgs suit la derniere release upstream.
    # le paquet source est dans le cache. losslesscut-bin reconstruirait un wrapper fhs en local.
    pkgs.losslesscut
    # prise de notes. unfree, autorise globalement (modules/shared/nix.nix).
    pkgs.obsidian
    # suivi du systeme. btm : processus, disques, reseau, temperatures.
    # nvtop : la rtx 4070. la config de btm est liee juste en dessous.
    # les lanceurs remplacent le .desktop d'origine (meme nom de fichier).
    pkgs.bottom
    pkgs.nvtopPackages.nvidia
    (monitorLauncher {
      name = "bottom";
      desktopName = "Bottom";
      class = "ws6-btm";
      command = "btm";
      icon = "bottom-system-monitor";
    })
    (monitorLauncher {
      name = "nvtop";
      desktopName = "Nvtop";
      class = "ws6-nvtop";
      command = "nvtop";
      icon = "nvtop";
    })
  ];

  # btm lit ~/.config/bottom/bottom.toml. le lien n'est que sur games :
  # navi n'a pas le paquet.
  hjem.users.${username}.files.".config/bottom/bottom.toml".source = ../../config/bottom/bottom.toml;
}
