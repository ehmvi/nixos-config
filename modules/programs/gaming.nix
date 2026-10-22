# module: programs/gaming
# steam + proton-ge + nintendo controller support
{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  environment.systemPackages = [
    pkgs.archipelago
    pkgs.poptracker # progression tracker for archipelago randomizers
    pkgs.lutris
  ];

  # regles udev : manettes nintendo, souris endgame gear, clavier melgeek
  # uaccess = acces pour la session active seulement. fichier 70-* car uaccess doit
  # etre pose avant 73-seat-late.rules (extraRules finit en 99-local.rules : trop tard)
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-gaming.rules" ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3367", ATTRS{idProduct}=="1978", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3367", ATTRS{idProduct}=="1976", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3367", ATTRS{idProduct}=="1966", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="0114", TAG+="uaccess"
    '')
  ];
  # ntsync : primitives de sync windows cote noyau, utilisees par proton-ge (/dev/ntsync)
  boot.kernelModules = [
    "hid-nintendo"
    "ntsync"
  ];
}
