# module: programs/apps
# general graphical apps (browser, file manager, media, terminals, editors, chat)
{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    brave
    kdePackages.ark
    kdePackages.dolphin # file manager
    kdePackages.kio # kio plumbing (required)
    kdePackages.kio-extras # extra protocols (sftp, etc.)
    kdePackages.kio-fuse # mount remote filesystems
    kdePackages.breeze-icons # icon theme (avoids blank icons)
    imv
    mpv
    obs-studio
    ente-auth
    gajim
    mumble # chat vocal
    signal-desktop
    # messagerie simplex. l'appimage est dans le cache ; le wrapper fhs s'assemble en local
    simplex-chat-desktop
    equibop # client Discord principal, session/config séparées de Vesktop (voulu)
    vesktop # 2e client Discord, session/config séparées d'Equibop (voulu)
    wezterm
    zed-editor
    kdePackages.kate
    kdePackages.qttools
    kdePackages.kdenlive
    # kopuz : lecteur de musique, pas dans nixpkgs -> paquet fourni par son propre flake
    inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.default
    # grok-bot : hors nixpkgs, appimage epingle dans pkgs/grok-bot.nix
    (callPackage ../../pkgs/grok-bot.nix { })
  ];

  # file type (mime) → default application associations
  xdg.mime.defaultApplications = {
    "image/png" = "imv.desktop";
    "image/jpeg" = "imv.desktop";
    "image/gif" = "imv.desktop";
    "image/webp" = "imv.desktop";
    "image/bmp" = "imv.desktop";
    "image/tiff" = "imv.desktop";
    "image/svg+xml" = "imv.desktop";
    "image/x-icon" = "imv.desktop";
  };
}
