# module: desktop/hyprland
# hyprland + hyprlock + wayland ecosystem packages
{
  config,
  pkgs,
  ...
}:

{
  programs.hyprland.enable = true;
  # uwsm demarre graphical-session.target. sans ca, xdg-desktop-portal
  # (requisite sur cette cible) echoue en "dependency failed"
  programs.hyprland.withUWSM = true;
  programs.hyprlock.enable = true;

  # uwsm (prepare-env.sh) exporte XDG_MENU_PREFIX=hyprland-, mais personne ne fournit
  # hyprland-applications.menu : kservice ne construit alors aucun arbre d'applis et
  # le menu "ouvrir avec" de dolphin reste vide. le nom du fichier suit la session,
  # d'ou sa place ici plutot que dans apps.nix. menu minimal, sans plasma-workspace
  environment.etc."xdg/menus/hyprland-applications.menu".source =
    ../../config/xdg/hyprland-applications.menu;

  # agent polkit (fenetre de mot de passe pour les actions privilegiees), absent par
  # defaut sous hyprland. on rend son unite systemd dispo, lancee depuis hyprland.lua
  systemd.packages = [ pkgs.hyprpolkitagent ];

  # coffre a secrets (org.freedesktop.secrets) absent sous hyprland : ente auth, signal,
  # brave... y rangent leurs cles. deverrouille a la connexion sddm avec le mot de passe
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # synthese vocale active par defaut sur tout bureau nixos. personne ne l'utilise
  # ici, et elle tire espeak et toutes les voix mbrola (700 mo de store).
  services.speechd.enable = false;

  environment.systemPackages = with pkgs; [
    rofi
    brightnessctl
    wayle
    hyprshot
    # claude code colle les images (ctrl+v) via wl-paste ou xclip.
    # hyprshot embarque wl-copy pour lui seul, pas dans le path.
    wl-clipboard
    # historique du presse-papiers, alimente par wl-paste --watch (hyprland.lua).
    # le binaire seul : les scripts contrib tirent fuzzel, fzf, wofi, chafa et
    # resvg (une cinquantaine de mo) pour des menus qu'on n'utilise pas
    (cliphist.overrideAttrs {
      postPatch = "";
      postInstall = "";
    })
    matugen # extrait une palette du fond d ecran (lance par wayle, theme-provider)
    awww # moteur de fond d ecran pilote par wayle (wayle lance awww-daemon lui-meme)
    hyprsunset # filtre de lumiere bleue, lance et tue par le module hyprsunset de wayle
    playerctl
    # hook matugen : meme hyprland que la session, pour que hyprctl corresponde
    (callPackage ../../pkgs/apply-hypr-colors.nix {
      hyprland = config.programs.hyprland.package;
    })
  ];
}
