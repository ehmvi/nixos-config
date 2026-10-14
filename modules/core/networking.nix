# module: core/networking
# networkmanager + tailscale + mullvad + firewall rules
{ config, ... }:

{
  networking.networkmanager.enable = true;

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;
  # hors nix : `mullvad lan set allow` (a refaire apres reinstall), sinon tailscale
  # passe par un relais derp au lieu du lan quand mullvad est connecte
  services.resolved.enable = true;

  # tailscaled accepte lui-meme le trafic de tailscale0 (chaine ts-input, avant les
  # regles nixos), donc trustedInterfaces n'y change rien. l'entrant est bloque par
  # shields-up (aucun service expose, juste du ssh sortant vers le pi). le vrai
  # controle d'acces au tailnet = les acls tailscale.
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--shields-up" ];
  };

  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
