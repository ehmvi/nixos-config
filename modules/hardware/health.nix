# module: hardware/health
# surveillance matérielle : santé des ssd (smart), capteurs, test de ram au boot
{ pkgs, ... }:

{
  # smartd surveille les disques en tache de fond : alerte desktop (wayle via
  # systembus-notify, wall/x11 restent invisibles sous hyprland), seuils de
  # temperature nvme (55 info / 65 critique) et auto-tests court hebdo / long mensuel.
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -W 4,55,65 -s (S/../../7/03|L/../01/./04)";
    notifications = {
      x11.enable = false;
      systembus-notify.enable = true;
    };
  };

  # ajoute une entrée memtest86+ au menu systemd-boot (test de ram ponctuel)
  boot.loader.systemd-boot.memtest86.enable = true;

  environment.systemPackages = with pkgs; [
    smartmontools # smartctl : usure et erreurs des ssd
    lm_sensors # sensors : températures cpu/carte mère
    nvme-cli # infos détaillées nvme
  ];
}
