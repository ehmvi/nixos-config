# host: sommei
# macbook pro m1 — nix-darwin/daily driver
{
  pkgs,
  theme,
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
in
{
  imports = [
    ../../modules/shared/nix.nix
    ../../modules/programs/godot-android.nix
    ../../modules/programs/craft.nix
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

  # fsa : traitement du micro en temps reel, sortie vers le micro virtuel blackhole 2ch.
  # le module copie le driver dans /Library/Audio/Plug-Ins/HAL a l activation
  programs.fsa.enable = true;

  # sketchybar : barre du haut a la place de la barre de menus macos (masquee plus bas,
  # elle reapparait en survolant le haut de l'ecran). agent launchd utilisateur ;
  # le rc est rendu avec theme.nix, les plugins sont lus depuis le store.
  services.sketchybar = {
    enable = true;
    extraPackages = [ pkgs.jq ];
    config = builtins.replaceStrings [ "@plugins@" ] [ "${../../config/sketchybar/plugins}" ] (
      theme.render ../../config/sketchybar/sketchybarrc
    );
  };

  # yabai : gestionnaire de fenetres bsp facon hyprland. la scripting addition
  # (sip partiellement desactive, voir docs/darwin-bootstrap.md) donne la bascule
  # instantanee entre espaces, le deplacement de fenetres et les regles silencieuses.
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    config = {
      layout = "bsp";
      auto_balance = "off";
      split_ratio = 0.5;
      window_placement = "second_child";
      window_gap = 6;
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      external_bar = "all:36:0";
      mouse_follows_focus = "off";
      focus_follows_mouse = "off";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
      window_shadow = "float";
    };
    extraConfig = builtins.readFile ../../config/yabai/extra.sh;
  };

  # skhd : raccourcis clavier alignes sur config/hypr/hyprland.lua (mainMod = lalt)
  services.skhd = {
    enable = true;
    skhdConfig = builtins.readFile ../../config/skhd/skhdrc;
  };

  # jankyborders : bordures carrees de 2 px sur les fenetres, couleurs de theme.nix
  services.jankyborders = {
    enable = true;
    style = "square";
    width = 2.0;
    hidpi = true;
    active_color = "0xff${builtins.substring 1 6 theme.accentHex}";
    inactive_color = "0xff${builtins.substring 1 6 theme.palette.surface0}";
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
    user = username;
    autoMigrate = true;
    enableRosetta = false;
  };

  # homebrew — piloté déclarativement par nix-darwin
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    # tout ce qui est declare ici est garde ; le cleanup "uninstall" ne retire que le reste
    taps = [
      "anomalyco/tap"
      "punarinta/msga"
    ];
    brews = [
      "bash"
      "handbrake"
      "mole"
      "anomalyco/tap/opencode-v2"
    ];
    casks = [
      # limite la charge batterie (80 %) quand le mac reste branche
      "aldente"
      # ardia : navigateur chromium (sidebar facon arc), cask officiel, se met a jour seul
      "ardia"
      "brave-browser"
      "bitwarden"
      "ente-auth"
      "vesktop" # 2e client Discord, session/config séparées d'Equibop (voulu)
      # nixpkgs equibop est linux-only : le cask officiel couvre macos
      "equibop" # client Discord principal, session/config séparées de Vesktop (voulu)
      "font-jetbrains-mono-nerd-font"
      "gstreamer-runtime"
      "grok-bot"
      # terminal principal (kitty.conf gere par hjem plus bas)
      "kitty"
      "marta"
      "monal"
      # client pour regarder le bureau de games via tailscale
      "moonlight"
      "mullvad-browser"
      "mullvad-vpn"
      "obsidian"
      # msga : client slack natif (c++), pas electron. non notarise : au premier
      # lancement, reglages > confidentialite et securite > "ouvrir quand meme".
      "punarinta/msga/msga"
      "super-productivity"
      "xquartz"
      "hopper-disassembler"
      "handbrake-app"
      "zen"
      # t3 code : interface pour les agents. cask par preference, comme les autres apps graphiques.
      # attention : pas de reglage claude/codex ici, il utilise ce qu'il trouve dans le path.
      "t3-code"
      # godot 4.5, jdk 17 et le sdk android : modules/programs/godot-android.nix
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
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
    # mistral vibe : agent de code (vibe, vibe-acp), comme sur navi et games
    (callPackage ../../pkgs/mistral-vibe.nix { })
    # ladybird : pas de cask, le .dmg officiel (lie dans /Applications/Nix Apps)
    (callPackage ../../pkgs/ladybird-darwin.nix { })
    # timon : pas de cask, le .dmg officiel (lie dans /Applications/Nix Apps)
    (callPackage ../../pkgs/timon-darwin.nix { })
  ];

  # hjem — declarative dotfiles
  hjem.users.${username} = {
    # pas config.users.users.${username}.home : nix-darwin le laisse a null tant qu on ne le declare pas
    directory = "/Users/${username}";
    files = {
      ".config/kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      ".config/kitty/themes/eva24.conf".source = ../../config/kitty/themes/eva24.conf;
      # meme prompt et fastfetch que navi et games, couleurs de theme.nix
      ".config/fastfetch/config.jsonc".text = theme.render ../../config/fastfetch/config.jsonc;
      ".config/starship.toml".text = theme.render ../../config/starship/starship.toml;
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

  # caps lock ne verrouille plus les majuscules. il devient option gauche
  # (lalt), le mainMod de config/skhd/skhdrc, comme super sur navi et games
  # (kb_options caps:super dans config/hypr/hyprland.lua). commande reste
  # intacte pour les raccourcis macos, et option droite (ralt) reste libre
  # pour les accents de qwerty-fr.
  # 0x700000039 caps lock, 0x7000000e2 left option (lalt).
  # hidutil tourne a chaque just switch, et encore au boot
  # (activate-system). une deconnexion peut la perdre jusqu'au prochain
  # switch ou reboot.
  system.keyboard.enableKeyMapping = true;
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771129;
      HIDKeyboardModifierMappingDst = 30064771298;
    }
  ];

  # réglages macos déclaratifs
  system.defaults.dock = {
    autohide = true;
    # garde l'ordre fixe des espaces 1..10 pour yabai
    mru-spaces = false;
    orientation = "bottom";
    tilesize = 42;
    show-recents = false;
    expose-animation-duration = 0.1;
  };

  # requis par yabai : chaque ecran a ses propres espaces
  system.defaults.spaces.spans-displays = false;

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
    NSAutomaticWindowAnimationsEnabled = false;
    # la barre de menus se cache : sketchybar prend sa place
    _HIHideMenuBar = true;
  };

  system.defaults.screencapture = {
    location = "~/Pictures/screenshots";
    type = "png";
  };
}
