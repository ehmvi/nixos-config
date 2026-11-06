# host: games
# desktop pc — gaming/multimedia
{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  # le .desktop du paquet ouvre le programme dans un terminal quelconque,
  # sans classe, donc hyprland ne peut pas le placer. celui-ci passe devant
  # et ouvre wezterm avec une classe a lui, envoyee sur le workspace 10.
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
in

{
  imports = [
    ./hardware.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/health.nix
    ../../modules/hardware/nvidia-power.nix
    ../../modules/hardware/coolercontrol.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/programs/cli.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/office.nix
    ../../modules/programs/apps.nix
    ../../modules/programs/spicetify.nix
    ../../modules/programs/sunshine.nix
    ../../modules/programs/ollama.nix
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

  # compresse ce qui s'ecrit a partir de maintenant, sans lourdeur sur ce cpu (niveau 1).
  # btrfs saute seul ce qui se compresse mal (videos, modeles). une partie des jeux reste
  # compressee : lire 100 mo/s coute alors environ 7 % d'un coeur. une option de montage
  # vaut pour tout le volume, donc / et /home. noatime : pas d'ecriture a chaque lecture.
  fileSystems."/".options = [
    "compress=zstd:1"
    "noatime"
  ];
  fileSystems."/home".options = [
    "compress=zstd:1"
    "noatime"
  ];
  # scrub mensuel : relit chaque bloc et verifie sa somme de controle, seul moyen
  # de voir une corruption silencieuse. / et /home sont le meme volume, un seul
  # scrub couvre les deux. le trim hebdomadaire est deja actif (fstrim par defaut).
  # le module le lance en cpu idle. sa priorite d'e/s ne compte pas en ordonnanceur
  # none : un scrub pendant un jeu peut ralentir ses chargements, quelques minutes.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  # artcraft launcher installe les apps en appimage dans ~/Applications et les
  # lance directement. binfmt les fait passer par appimage-run : sans lui, nixos
  # refuse de les demarrer (pas de /lib64/ld-linux).
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # nixpkgs marque ventoy "insecure" a cause de ses blobs binaires, quelle que
  # soit la version (nixpkgs#404663). le filtre porte sur le nom : une liste
  # permittedInsecurePackages casserait l'eval a chaque release. ce predicat
  # remplace cette liste : elle serait ignoree ici.
  nixpkgs.config.allowInsecurePredicate = pkg: lib.getName pkg == "ventoy";

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
    # msga : client slack natif (c++), pas electron. paquet du flake amont,
    # construit en local (pas de cache). mise a jour : nix flake update msga.
    inputs.msga.packages.${pkgs.stdenv.hostPlatform.system}.default
    # lanceur minecraft. le paquet embarque les jdk 8, 17, 21 et 25.
    pkgs.prismlauncher
    # cles usb multiboot. ventoy en terminal, ventoy-web pour l'interface web
    # sur localhost. les deux demandent root. unfree et insecure, voir plus haut.
    pkgs.ventoy
    # t3 code nightly, a cote de la stable (modules/programs/apps.nix). donnees
    # separees dans ~/.t3-nightly, voir le paquet.
    (pkgs.callPackage ../../pkgs/t3code-nightly.nix { })
    # lanceur de la suite craft (photocraft, filmcraft...). release linux officielle.
    (pkgs.callPackage ../../pkgs/artcraft-launcher.nix { })
    # daw. nixpkgs suit la derniere release upstream. unfree, donc hors du
    # cache : le .deb se telecharge et le paquet se construit en local.
    pkgs.bitwig-studio
    # hermes desktop (nous research) : electron, avec le runtime hermes du
    # meme flake. l'etat reste dans ~/.hermes.
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
    # suivi du systeme. btm : processus, disques, reseau, temperatures.
    # nvtop : la rtx 4070. la config de btm est liee juste en dessous.
    # les lanceurs remplacent le .desktop d'origine (meme nom de fichier).
    pkgs.bottom
    pkgs.nvtopPackages.nvidia
    (monitorLauncher {
      name = "bottom";
      desktopName = "Bottom";
      class = "ws10-btm";
      command = "btm";
      icon = "bottom-system-monitor";
    })
    (monitorLauncher {
      name = "nvtop";
      desktopName = "Nvtop";
      class = "ws10-nvtop";
      command = "nvtop";
      icon = "nvtop";
    })
  ];

  # btm lit ~/.config/bottom/bottom.toml. le lien n'est que sur games :
  # navi n'a pas le paquet.
  hjem.users.${username}.files.".config/bottom/bottom.toml".source = ../../config/bottom/bottom.toml;
}
