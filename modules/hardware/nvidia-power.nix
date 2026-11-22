# module: hardware/nvidia-power
# limite de puissance de la rtx 4070 : 170 w au lieu de 200 w
# moins de chaleur et de bruit pour une perte de perf quasi nulle
{ config, ... }:

{
  # garde le pilote chargé en permanence, sinon la limite peut être perdue
  hardware.nvidia.nvidiaPersistenced = true;

  # applique la limite au demarrage et apres chaque sortie de veille :
  # le pilote remet la limite par defaut (200 w) au reveil.
  systemd.services.nvidia-power-limit = {
    description = "limite de puissance gpu (170 w)";
    wantedBy = [
      "multi-user.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    after = [
      "nvidia-persistenced.service"
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 170";
    };
  };
}
