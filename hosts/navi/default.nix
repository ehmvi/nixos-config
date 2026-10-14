# host: navi
# personal thinkpad — intel laptop hardware
{ pkgs, ... }:

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

  fyrr.wayle.configFile = ../../config/wayle/config-navi.toml;

  # upower : etat de la batterie pour les autres programmes (module battery de wayle)
  services.upower.enable = true;
  # profils d energie (economie / equilibre / performance) : powerprofilesctl
  services.power-profiles-daemon.enable = true;
  # thermald : demon intel qui limite la chauffe du cpu avant le throttling brutal
  services.thermald.enable = true;

  # va-api : decodage video par le gpu intel au lieu du cpu
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # fwupd : mises a jour firmware (bios, thunderbolt, ssd) via lvfs, ou lenovo publie
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    powertop
  ];

  system.stateVersion = "25.11";
}
