# host: games
# desktop pc — gaming/multimedia
{
  pkgs,
  ...
}:

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
  ];

  networking.hostName = "games";
  console.keyMap = "fr";
  # dual boot : la rtc reste en utc. côté windows, clé registre RealTimeIsUniversal = 1
  services.xserver.xkb.layout = "fr";
  fyrr.wayle.configFile = ../../config/wayle/config-games.toml;

  boot.kernelModules = [ "nct6775" ];

  programs.coolercontrol.enable = true;

  system.stateVersion = "25.11";
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/egctl.nix { })
  ];
}
