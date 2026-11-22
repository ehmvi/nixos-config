# module: core/system
# boot, locale, nix daemon, zram, shared cli packages
{
  lib,
  pkgs,
  theme,
  ...
}:

{
  boot.loader.systemd-boot.enable = true;
  # 10 générations max dans le menu de boot : évite de remplir l esp (/boot)
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # console : police terminus (chaque host choisit sa taille avec console.font),
  # chargee des l'initrd pour que le texte de boot soit lisible lui aussi.
  # couleurs du tty = les 16 ansi du theme, comme wezterm
  console.earlySetup = true;
  console.packages = [ pkgs.terminus_font ];
  console.colors = map (c: builtins.substring 1 6 c) theme.ansi16;

  # mkDefault : valeurs partagees, un host peut les surcharger sans mkForce
  time.timeZone = lib.mkDefault "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  # mkDefault par cle : un host qui surcharge une seule variable lc_ garde les autres
  i18n.extraLocaleSettings = lib.mapAttrs (_: lib.mkDefault) {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # dates/persistent : options systemd, retirees sur nix-darwin.
  # automatic et options sont dans modules/shared/nix.nix.
  nix.gc = {
    dates = "weekly";
    persistent = true;
  };

  # dedoublonnage du store en tache de fond (idle par defaut) plutot qu'a
  # chaque ecriture : rebuilds et nix develop plus rapides, meme gain disque.
  # decale apres nix-gc (lundi 00h) pour ne pas dedoublonner des chemins en cours de suppression.
  nix.optimise = {
    automatic = true;
    dates = [ "Mon *-*-* 03:00:00" ];
  };

  # builds et gc passent apres le reste : une mise a jour ne fait pas saccader
  # un jeu ou un stream. ils gardent tout le cpu quand rien d'autre ne tourne.
  # pas de priorite d'e/s : les nvme sont en ordonnanceur none, qui l'ignore.
  nix.daemonCPUSchedPolicy = "idle";
  systemd.services.nix-gc.serviceConfig.CPUSchedulingPolicy = "idle";

  # /tmp en ram : moins d'ecritures ssd et pas de menage disque au boot.
  # mkDefault pour laisser un hote ajuster ou couper selon sa ram.
  boot.tmp.useTmpfs = lib.mkDefault true;

  # swap compressé en ram (zram) : filet de sécurité quand la ram est pleine, zéro écriture disque
  zramSwap.enable = true;

  # oomd surveille la pression memoire des sessions utilisateur : evite de
  # figer le bureau si un processus (llm, navigateur, build) sature la ram.
  systemd.oomd.enableUserSlices = true;

  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    # zram relit une page en ram, bien plus vite qu'un fichier sur ssd : le noyau
    # compresse d'abord ce qui dort et garde le cache disque. valeurs du wiki arch (zram).
    "vm.swappiness" = 180;
    # pas de lecture groupee : zram n'a aucun temps d'acces a economiser
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    # seuils fixes au lieu des ratios (10/20 % = plusieurs go sur 64 go) :
    # evite les rafales d'ecritures sur le ssd et les saccades d'e/s.
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;
    "vm.dirty_bytes" = 256 * 1024 * 1024;
    # garde plus longtemps en ram le cache d'inodes/dentries (nix store, btrfs, git)
    "vm.vfs_cache_pressure" = 50;
    # bbr + fq : latence reseau plus stable sous charge (telechargements, stream tailscale)
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # le watchdog nmi reveille chaque coeur et occupe un compteur de perf, pour du debug noyau
    "kernel.nmi_watchdog" = 0;
  };

  # 256 mo de journaux suffisent ici, le defaut monte a 4 go
  services.journald.settings.Journal.SystemMaxUse = "256M";

  # mounts removable drives (usb sticks); not enabled outside plasma, so i enable it explicitly
  services.udisks2.enable = true;

  # git via le module nixos : il installe le paquet, sans le dupliquer ici.
  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    fastfetch
    unzip
    claude-code
    # paquet seul et pas programs.starship : le module nixos n initialise que
    # bash/zsh/fish/xonsh, pas nushell. l'init nu est l'autoload ci-dessous
    starship
  ];

  # init starship generee au build en autoload vendor (programs.nushell, core/users),
  # au lieu de `starship init nu | save` a chaque demarrage de shell.
  # nom en -init : le paquet fournit deja starship.nu (ses completions)
  programs.nushell.autoloads = [
    (pkgs.runCommand "starship-nushell-autoload" { } ''
      export HOME=$TMPDIR
      mkdir -p $out/share/nushell/vendor/autoload
      ${lib.getExe pkgs.starship} init nu > $out/share/nushell/vendor/autoload/starship-init.nu
    '')
  ];
}
