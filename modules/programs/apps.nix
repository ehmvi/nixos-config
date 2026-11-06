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
    equibop # client Discord principal, session/config séparées de Vesktop (voulu)
    vesktop # 2e client Discord, session/config séparées d'Equibop (voulu)
    wezterm
    zed-editor
    # t3 code : interface pour les agents. claude code a la place de codex.
    # gh et git restent. navi et games seulement (ce module n'est pas
    # importe par sommei, qui prend le cask).
    (t3code.override {
      enableClaude = true;
      enableCodex = false;
      # les images derriere un lien symbolique qui sort du workspace (docs/ d'un worktree) s'ouvrent
      t3code-unwrapped = t3code.unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../pkgs/t3code-symlinked-workspace-images.patch ];
      });
    })
    # mistral vibe : agent de code, fournit vibe et vibe-acp (que t3 code lance
    # via le registre acp). connexion par navigateur = forfait mistral, pas de cle api.
    mistral-vibe
    kdePackages.kate
    kdePackages.qttools
    kdePackages.kdenlive
    # kopuz : lecteur de musique, pas dans nixpkgs -> paquet fourni par son propre flake
    inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.default
    # grok-bot : hors nixpkgs, appimage epingle dans pkgs/grok-bot.nix
    (callPackage ../../pkgs/grok-bot.nix { })
  ];

  # bitwarden reecrit ~/.config/autostart tant que son option "start at login" est
  # cochee : on masque l'unite que systemd en tire. le lancer a la main marche toujours.
  systemd.user.units."app-bitwarden@autostart.service".enable = false;

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
