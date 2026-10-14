# host: sommei
# macbook pro m1 — nix-darwin/daily driver
{
  config,
  pkgs,
  inputs,
  username,
  ...
}:

let
  zenProfilesIni = pkgs.writeText "zen-profiles.ini" ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Name=default
    IsRelative=1
    Path=Profiles/default
    Default=1
  '';

  # flake amont, packages.${system}.default. pas de inputs.nixpkgs.follows :
  # le cache ne contient que les binaires construits avec leur nixpkgs.
  kopuz = inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # le flake pose Kopuz.app dans $out/bin. nix-darwin ne publie dans
  # /Applications/Nix Apps que les bundles sous $out/Applications.
  # kopuzd est le binaire headless : l app desktop demarre le coeur
  # elle-meme, donc pas de service launchd.
  kopuzApp = pkgs.symlinkJoin {
    name = "kopuz";
    paths = [ kopuz ];
    postBuild = ''
      mkdir -p $out/Applications
      ln -s ${kopuz}/bin/kopuz.app $out/Applications/Kopuz.app
    '';
  };
in
{
  imports = [
    ../../modules/shared/nix.nix
    ../../modules/programs/godot-android.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  # optimisation du store via launchd. le gc (dimanche 3h15) vient du module
  # partage ; ici seulement l optimise, defaut dimanche 4h15.
  nix.optimise.automatic = true;

  system.primaryUser = username;
  system.stateVersion = 5;

  # touch id for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  # reattach : touch id marche aussi dans tmux / cmux (detaches de la session graphique)
  security.pam.services.sudo_local.reattach = true;

  # pare-feu applicatif macos : bloque les connexions entrantes non autorisees.
  # stealth mode : pas de reponse aux pings ni aux sondes de ports (wifi public)
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  # fish shell
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.knownUsers = [ username ];
  users.users.${username} = {
    uid = 501;
    shell = pkgs.fish;
  };

  # nix-homebrew — installe et épingle homebrew lui-même.
  # nix-darwin (bloc homebrew ci-dessous) ne gère que les paquets.
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    autoMigrate = true;
    enableRosetta = false;
  };

  # homebrew — piloté déclarativement par nix-darwin
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    brews = [
      "bash"
      "handbrake"
      "mole"
    ];
    casks = [
      "brave-browser"
      "bitwarden"
      "ente-auth"
      "vesktop" # 2e client Discord, session/config séparées d'Equibop (voulu)
      # nixpkgs equibop est linux-only : le cask officiel couvre macos
      "equibop" # client Discord principal, session/config séparées de Vesktop (voulu)
      "font-jetbrains-mono-nerd-font"
      "gstreamer-runtime"
      "grok-bot"
      "knockknock"
      "marta"
      "monal"
      "mullvad-browser"
      "mullvad-vpn"
      "obsidian"
      "utm"
      "xquartz"
      "hopper-disassembler"
      "handbrake-app"
      "zen"
      # godot 4.5, jdk 17 et le sdk android : modules/programs/godot-android.nix
    ];
  };

  environment.systemPackages =
    with pkgs;
    [
      git
      curl
      htop
      tmux
      cmux
      age
      tree
      neovim
      fastfetch
      screenfetch
      ffmpeg
      yt-dlp
      imagemagick
      exiftool
      figlet
      restic
      poppler-utils
      nodejs_22
      grc
      vcprompt
      wimlib
      just
      starship
      cinny-desktop # client matrix, Cinny.app dans /Applications/Nix Apps
    ]
    ++ [ kopuzApp ];

  # hjem — declarative dotfiles
  hjem.users.${username} = {
    # pas config.users.users.${username}.home : nix-darwin le laisse a null tant qu on ne le declare pas
    directory = "/Users/${username}";
    files = {
      ".config/kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      ".config/kitty/themes/eva24.conf".source = ../../config/kitty/themes/eva24.conf;
      ".config/starship.toml".source = ../../config/starship/starship.toml;
      ".config/fish/config.fish".source = ../../config/fish/config.fish;
      ".config/git/config".source = ../../config/git/config;
      "Library/Application Support/zen/Profiles/default/user.js".source = ../../config/zen/user.js;
    };
  };

  # zen réécrit profiles.ini lui-même : impossible de le symlinker depuis
  # le store, qui est en lecture seule. on le sème une seule fois, s'il
  # est absent, avec un nom de dossier FIXE. Sinon zen tire 8 caractères
  # au hasard au premier lancement et le user.js ci-dessus pointe dans le
  # vide. idempotent : ne touche à rien si le fichier existe déjà.
  system.activationScripts.postActivation.text = ''
    zenDir="/Users/${username}/Library/Application Support/zen"
    if [ ! -e "$zenDir/profiles.ini" ]; then
      mkdir -p "$zenDir/Profiles/default"
      cp ${zenProfilesIni} "$zenDir/profiles.ini"
      chmod u+w "$zenDir/profiles.ini"
      chown -R ${username}:staff "$zenDir"
    fi
  '';

  # réglages macos déclaratifs
  system.defaults.dock = {
    autohide = false;
    orientation = "bottom";
    tilesize = 42;
    show-recents = false;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    ShowPathbar = true;
    ShowStatusBar = false;
  };

  system.defaults.trackpad = {
    Clicking = true;
    TrackpadThreeFingerDrag = true;
  };

  system.defaults.NSGlobalDomain = {
    KeyRepeat = 3;
    InitialKeyRepeat = 15;
  };

  system.defaults.screencapture = {
    location = "~/Pictures/screenshots";
    type = "png";
  };
}
