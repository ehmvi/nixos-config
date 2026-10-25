# module: core/networking
# networkmanager + tailscale + mullvad + firewall rules
{
  config,
  lib,
  ...
}:

{
  networking.networkmanager.enable = true;

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;
  # hors nix : `mullvad lan set allow` (a refaire apres reinstall), sinon tailscale
  # passe par un relais derp au lieu du lan quand mullvad est connecte
  services.resolved.enable = true;

  # tailscale 1.104 insere `-j ts-input` en tete d'INPUT, et ts-input
  # contient `-i tailscale0 -j ACCEPT`. cet accept est final : nixos-fw
  # ne voit pas ce trafic. trustedInterfaces n'y change rien.
  # shields-up, lui, jette l'entrant dans tailscaled, avant l'interface.
  # navi le garde. games le coupe : la le filtre, ce sont les acls du tailnet.
  # sommei n'a pas ce module (appli mac, hors de ce depot).
  services.tailscale = {
    enable = true;
    # mkDefault : games remplace la liste. sans ca, nixos additionne
    # les deux et enverrait --shields-up et --shields-up=false ensemble.
    extraSetFlags = lib.mkDefault [ "--shields-up" ];
  };

  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
