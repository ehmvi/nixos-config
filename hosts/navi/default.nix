# host: navi
# personal thinkpad — intel laptop hardware
{ pkgs, username, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/intel.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/programs/cli.nix
    ../../modules/programs/office.nix
    ../../modules/programs/apps.nix
  ];

  networking.hostName = "navi";

  # pas d'ecriture sur le ssd a chaque lecture
  fileSystems."/".options = [ "noatime" ];

  fyrr.wayle.configFile = ../../config/wayle/config-navi.toml;
  # hyprlock : memes dispositions que kb_layout dans hyprland.lua, et la batterie
  fyrr.hyprlock.layouts = [
    "us"
    "fr"
  ];
  fyrr.hyprlock.battery = "BAT0";

  # terminus 16x32, la plus grande : la police par defaut est minuscule a cette densite
  console.font = "ter-v32n";
  # pas de dual boot ici : 2 s suffisent pour choisir une generation precedente
  boot.loader.timeout = 2;

  # upower : etat de la batterie pour les autres programmes (module battery de wayle)
  services.upower.enable = true;
  # batterie critique : extinction propre, le travail non enregistre est perdu.
  # le defaut HybridSleep suppose une hibernation, impossible ici (zram seul,
  # pas de swap disque) : on ecrit l'action qui a vraiment lieu.
  services.upower.criticalPowerAction = "PowerOff";
  # profils d energie (economie / equilibre / performance) : powerprofilesctl
  services.power-profiles-daemon.enable = true;
  # thermald : demon intel qui limite la chauffe du cpu avant le throttling brutal
  services.thermald.enable = true;

  # va-api : decodage video par le gpu intel au lieu du cpu
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  # mpv s'en sert. pas sur games : nvdec fait passer la rtx de p8 a p2, 18 w de plus
  # (mesure en 1440p h264) pour 0,4 coeur gagne.
  hjem.users.${username}.files.".config/mpv/mpv.conf".source = ../../config/mpv/mpv.conf;

  # fwupd : mises a jour firmware (bios, thunderbolt, ssd) via lvfs, ou lenovo publie
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    powertop
    # messagerie simplex, navi seulement. l'appimage est dans le cache ; le wrapper fhs s'assemble en local
    simplex-chat-desktop
  ];

  system.stateVersion = "25.11";
}
