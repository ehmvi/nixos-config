# module: desktop/hyprland
# hyprland + hyprlock + wayland ecosystem packages
{
  config,
  pkgs,
  ...
}:

{
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # agent polkit (fenetre de mot de passe pour les actions privilegiees), absent par
  # defaut sous hyprland. on rend son unite systemd dispo, lancee depuis hyprland.lua
  systemd.packages = [ pkgs.hyprpolkitagent ];

  # coffre a secrets (org.freedesktop.secrets) absent sous hyprland : ente auth, signal,
  # brave... y rangent leurs cles. deverrouille a la connexion sddm avec le mot de passe
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    rofi
    brightnessctl
    wayle
    hyprshot
    matugen # extrait une palette du fond d ecran (lance par wayle, theme-provider)
    awww # moteur de fond d ecran pilote par wayle (wayle lance awww-daemon lui-meme)
    playerctl
    # hook matugen : meme hyprland que la session, pour que hyprctl corresponde
    (callPackage ../../pkgs/apply-hypr-colors.nix {
      hyprland = config.programs.hyprland.package;
    })
  ];
}
