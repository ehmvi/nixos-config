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

  services.tailscale.enable = true;

  # tailscale0 volontairement pas dans trustedInterfaces : aucun service n'est
  # exposé sur le tailnet, ces hosts ne font que du ssh sortant vers le pi
  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
