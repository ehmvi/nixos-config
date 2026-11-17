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
      # client pour regarder le bureau de games via tailscale
      "moonlight"
      "mullvad-browser"
      "mullvad-vpn"
      "obsidian"
      # msga : client slack natif (c++), pas electron. non notarise : au premier
      # lancement, reglages > confidentialite et securite > "ouvrir quand meme".
      "punarinta/msga/msga"
      "utm"
      "xquartz"
      "hopper-disassembler"
      "handbrake-app"
      "zen"
      # t3 code : interface pour les agents. cask par preference, comme les autres apps graphiques.
      # attention : pas de reglage claude/codex ici, il utilise ce qu'il trouve dans le path.
      "t3-code"
      # a cote de la beta, mais memes donnees (~/.t3/userdata) : une seule des deux
      # ouverte a la fois, et la nightly y applique ses migrations. elle se met a jour seule.
      "t3-code@nightly"
      # godot 4.5, jdk 17 et le sdk android : modules/programs/godot-android.nix
    ];
  };

  environment.systemPackages = with pkgs; [
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
    # mistral vibe : agent de code (vibe, vibe-acp), comme sur navi et games
    (callPackage ../../pkgs/mistral-vibe.nix { })
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
      # meme prompt que navi et games, couleurs de theme.nix
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

  # caps lock ne verrouille plus les majuscules. il devient commande
  # gauche, partout, comme super sur games (kb_options caps:super dans
  # config/hypr/hyprland.lua, pour tous les claviers).
  # 0x700000039 caps lock, 0x7000000e3 left gui (commande / super).
  # hidutil tourne a chaque just switch, et encore au boot
  # (activate-system). pas besoin de se deconnecter pour l'installer.
  # la table n'est pas un reglage macos durable : une deconnexion peut
  # la perdre jusqu'au prochain switch ou reboot.
  # cmd+tab et cmd+espace partent aussi de caps lock.
  system.keyboard.enableKeyMapping = true;
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771129;
      HIDKeyboardModifierMappingDst = 30064771299;
    }
  ];

  # réglages macos déclaratifs
  system.defaults.dock = {
    autohide = false;
    orientation = "bottom";
    tilesize = 42;
    show-recents = false;
    # cette liste remplace tout le dock a chaque switch : un ajout ou un
    # deplacement a la souris est perdu au switch suivant, il faut le
    # reporter ici.
    # une app absente garde sa place avec une icone en point
    # d'interrogation. sur un mac neuf les defaults passent avant homebrew,
    # donc les casks ne s'affichent bien qu'apres un second switch.
    persistent-apps = [
      "/Applications/KeePassXC.app"
      "/Applications/Ente Auth.app"
      "/Applications/Bitwarden.app"
      "/Applications/kitty.app"
      "/Applications/Grok Bot.app"
      "/Applications/T3 Code (Beta).app"
      "/Applications/Zen.app"
      "/Applications/Zed.app"
      "/Applications/Moonlight.app"
    ];
    # partie droite du dock, vide aujourd'hui
    persistent-others = [ ];
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
