# module: programs/gaming
# steam + proton-ge + nintendo controller support
{
  lib,
  pkgs,
  username,
  ...
}:

{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # gamemode : pousse le gouverneur et la priorite seulement pendant un jeu,
  # puis revient aux reglages calmes a la fermeture.
  programs.gamemode.enable = true;
  users.users.${username}.extraGroups = [ "gamemode" ];

  # ananicy-cpp : ajuste automatiquement les priorites (jeux, pipewire, compositeur
  # devant les taches de fond) sans toucher aux tensions ni aux limites thermiques.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    # aucune regle cachyos n'utilise de cgroup : les couper evite 27 erreurs
    # cgroupv2 au boot et la creation de /sys/fs/cgroup/cpu{80,85,90}.
    # mkForce sur le workaround : nixpkgs l'a pose sans mkOptionDefault.
    settings = {
      cgroup_load = false;
      apply_cgroup = false;
      cgroup_realtime_workaround = lib.mkForce false;
    };
  };

  # l'unite amont pose MemoryHigh=16M, trop bas pour les ~110 000 lignes de
  # regles cachyos (pic > 16 mo, 4 mo en zram). 32 mo laisse le demon en ram.
  systemd.services.ananicy-cpp.serviceConfig.MemoryHigh = "32M";

  environment.systemPackages = [
    pkgs.lutris
  ];

  # regles udev : manettes nintendo, souris xbab, clavier melgeek
  # uaccess = acces pour la session active seulement. fichier 70-* car uaccess doit
  # etre pose avant 73-seat-late.rules (extraRules finit en 99-local.rules : trop tard)
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-gaming.rules" ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"
      # made68 air (0416:0114). l'interface 00 porte les frappes, la 01 est
      # le canal de config que hive ouvre. uaccess sur 00 laisserait un
      # programme de la session lire les frappes. on ne l'ouvre que sur 01.
      # idVendor vit sur le peripherique usb, bInterfaceNumber sur l'interface.
      # les ATTRS d'une meme regle doivent viser le meme parent, d'ou deux regles.
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="0114", ENV{MELGEEK_MADE68}="1"
      SUBSYSTEM=="hidraw", ENV{MELGEEK_MADE68}=="1", ATTRS{bInterfaceNumber}=="01", TAG+="uaccess"
      # souris xbab xa25 (16c0:27da), configuree par webhid sur ctrl.xbabtech.com.
      # l'interface 00 porte les mouvements, la 01 (page vendeur 0xffab) le canal de config.
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="27da", ENV{XBAB_XA25}="1"
      SUBSYSTEM=="hidraw", ENV{XBAB_XA25}=="1", ATTRS{bInterfaceNumber}=="01", TAG+="uaccess"
    '')
  ];
  # un jeu qui fait un split lock n'est plus endormi 10 ms par le noyau (reglage de steamos)
  boot.kernel.sysctl."kernel.split_lock_mitigate" = 0;

  # ntsync : primitives de sync windows cote noyau, utilisees par proton-ge (/dev/ntsync)
  boot.kernelModules = [
    "hid-nintendo"
    "ntsync"
  ];
}
