# module: programs/apps
# general graphical apps (browser, file manager, media, terminals, editors, chat)
{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # ardia : navigateur chromium, paquet et action polkit fournis par le flake amont
  imports = [ inputs.ardia.nixosModules.default ];
  programs.ardia.enable = true;

  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    brave
    # ladybird : .deb officiel ubuntu 24.04 (alpha), hors nixpkgs. sommei prend ladybird-darwin.nix
    (callPackage ../../pkgs/ladybird.nix { })
    # see : lecteur de code natif, tarball officiel hors nixpkgs. sommei prend see-darwin.nix
    (callPackage ../../pkgs/see.nix { })
    kdePackages.ark
    kdePackages.dolphin # file manager
    kdePackages.kio # kio plumbing (required)
    kdePackages.kio-extras # extra protocols (sftp, etc.)
    kdePackages.kio-fuse # mount remote filesystems
    # miniatures de dolphin : workers kio lances a la navigation, rien ne reste en memoire
    kdePackages.ffmpegthumbs # videos
    kdePackages.kdegraphics-thumbnailers # pdf, ps, raw
    kdePackages.kimageformats # webp, avif, heif, jxl
    imv
    mpv
    sioyek # lecteur pdf, pilote au clavier
    super-productivity # taches et suivi du temps. sommei prend le cask
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
    (callPackage ../../pkgs/mistral-vibe.nix { })
    # vibe est une tui : ce lanceur l'ouvre dans wezterm, classe vibe, que
    # hyprland envoie sur le workspace 1 (config/hypr/hyprland.lua).
    # sans --always-new-process, wezterm reutilise son processus et ignore --class.
    (makeDesktopItem {
      name = "mistral-vibe";
      desktopName = "Mistral Vibe";
      comment = "Mistral coding agent";
      exec = "wezterm start --always-new-process --class vibe -- vibe";
      icon = "utilities-terminal";
      startupWMClass = "vibe";
      categories = [ "Development" ];
    })
    kdePackages.kate
    kdePackages.qttools
    kdePackages.kdenlive
    # grok-bot : hors nixpkgs, appimage epingle dans pkgs/grok-bot.nix
    (callPackage ../../pkgs/grok-bot.nix { })
  ];

  # bitwarden reecrit ~/.config/autostart tant que son option "start at login" est
  # cochee : on masque l'unite que systemd en tire. le lancer a la main marche toujours.
  systemd.user.units."app-bitwarden@autostart.service".enable = false;

  # file type (mime) → default application associations
  # pas de joker dans mimeapps : chaque type est liste.
  # ~/.config/mimeapps.list passe avant /etc/xdg/mimeapps.list
  xdg.mime.defaultApplications =
    # images : imv
    {
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/x-icon" = "imv.desktop";
    }
    # video et audio : mpv
    // lib.genAttrs [
      "video/mp4"
      "video/x-matroska"
      "video/webm"
      "video/quicktime"
      "video/x-msvideo"
      "video/mpeg"
      "video/ogg"
      "video/x-flv"
      "audio/mpeg"
      "audio/flac"
      "audio/ogg"
      "audio/opus"
      "audio/x-vorbis+ogg"
      "audio/wav"
      "audio/x-wav"
      "audio/mp4"
      "audio/aac"
      "audio/webm"
    ] (_: "mpv.desktop")
    // {
      # pdf : sioyek
      "application/pdf" = "sioyek.desktop";
      # texte brut : zed
      "text/plain" = "dev.zed.Zed.desktop";
      # dossiers : dolphin
      "inode/directory" = "org.kde.dolphin.desktop";
      # navigateur : brave
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
    };
}
