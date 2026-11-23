# host: navi
# personal thinkpad — intel laptop hardware
{ pkgs, username, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/intel.nix
    ../../modules/hardware/health.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/programs/cli.nix
    ../../modules/programs/office.nix
    ../../modules/programs/apps.nix
    ../../modules/programs/craft.nix
    ../../modules/programs/timon.nix
  ];

  networking.hostName = "navi";

  # pas d'ecriture sur le ssd a chaque lecture, et flush du journal ext4 toutes les 60 s
  # (defaut 5 s) : moins de reveils disque et d'usure ssd sur batterie.
  fileSystems."/".options = [
    "noatime"
    "commit=60"
  ];

  fyrr.wayle.configFile = ../../config/wayle/config-navi.toml;
  # hyprlock : niveau de la batterie
  fyrr.hyprlock.battery = "BAT0";

  # terminus 16x32, la plus grande : la police par defaut est minuscule a cette densite
  console.font = "ter-v32n";
  # pas de dual boot ici : 2 s suffisent pour choisir une generation precedente
  boot.loader.timeout = 2;

  # upower : etat de la batterie pour les autres programmes (module battery de wayle)
  services.upower.enable = true;
  # profils d energie (economie / equilibre / performance) : powerprofilesctl
  services.power-profiles-daemon.enable = true;
  # thermald : demon intel qui limite la chauffe du cpu avant le throttling brutal
  services.thermald.enable = true;

  # seuils de charge thinkpad (75-80 %) : preserve la batterie li-ion sans tlp
  # (qui entrerait en conflit avec power-profiles-daemon).
  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75"
    "w /sys/class/power_supply/BAT0/charge_control_end_threshold - - - - 80"
  ];

  # va-api + quicksync/av1 (vpl-gpu-rt) : decodage et encodage video par le gpu intel
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
  ];
  # mpv s'en sert. pas sur games : nvdec fait passer la rtx de p8 a p2, 18 w de plus
  # (mesure en 1440p h264) pour 0,4 coeur gagne.
  hjem.users.${username}.files.".config/mpv/mpv.conf".source = ../../config/mpv/mpv.conf;

  # fwupd : mises a jour firmware (bios, thunderbolt, ssd) via lvfs, ou lenovo publie
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    powertop
    # messagerie simplex, navi seulement. l'appimage est dans le cache ; le wrapper fhs s'assemble en local
    simplex-chat-desktop
    # figma n'a pas de client linux officiel : figma-linux est l'enveloppe electron non officielle
    figma-linux
  ];

  system.stateVersion = "25.11";
}
