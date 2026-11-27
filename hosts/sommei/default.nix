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
    # see : pas de cask, le .app officiel (lie dans /Applications/Nix Apps)
    (callPackage ../../pkgs/see-darwin.nix { })
  ];

  # hjem — declarative dotfiles
  hjem.users.${username} = {
    # pas config.users.users.${username}.home : nix-darwin le laisse a null tant qu on ne le declare pas
    directory = "/Users/${username}";
    files = {
      ".config/kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      ".config/kitty/theme.conf".text = theme.render ../../config/kitty/theme.conf;
      # meme prompt et fastfetch que navi et games, couleurs de theme.nix
      ".config/fastfetch/config.jsonc".text = theme.render ../../config/fastfetch/config.jsonc;
      ".config/starship.toml".text = theme.render ../../config/starship/starship.toml;
      # meme theme zed "theme.nix" que navi et games, a choisir une fois dans zed
      ".config/zed/themes/theme-nix.json".text = theme.render ../../config/zed/theme.json;
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

    # dossiers images et captures (screencapture echoue si le dossier cible manque)
    for dir in "/Users/${username}/Pictures" "/Users/${username}/Pictures/screenshots"; do
      if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chown ${username}:staff "$dir"
      fi
    done

    # fond d'ecran herbanium : copie a un chemin stable (recopie seulement s'il change),
    # puis mode clair et fond sur tous les bureaux via system events. sans session
    # graphique, ou sans l'autorisation d'automatisation, on avertit sans echouer.
    wallpaper="/Users/${username}/Pictures/wallpaper.png"
    if ! cmp -s ${./wallpaper.png} "$wallpaper"; then
      cp ${./wallpaper.png} "$wallpaper"
      chmod 644 "$wallpaper"
      chown ${username}:staff "$wallpaper"
    fi
    # AppleInterfaceStyle = null n'efface pas une ancienne valeur Dark : on la retire ici
    if sudo --user=${username} -- defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
      sudo --user=${username} -- defaults delete -g AppleInterfaceStyle || true
    fi
    userUid=$(id -u ${username})
    if launchctl print "gui/$userUid" >/dev/null 2>&1; then
      launchctl asuser "$userUid" sudo --user=${username} -- /usr/bin/osascript \
        -e 'tell application "System Events"' \
        -e 'set dark mode of appearance preferences to false' \
        -e "tell every desktop to set picture to \"$wallpaper\"" \
        -e 'end tell' >/dev/null 2>&1 \
        || echo "herbanium : fond ou mode clair non applique (system events indisponible)" >&2
    fi

    # recharge les fenetres kitty deja ouvertes apres mise a jour de theme.conf
    pkill -USR1 -u ${username} -x kitty >/dev/null 2>&1 || true
  '';

  # caps lock ne verrouille plus les majuscules. il devient commande
  # gauche, partout, comme super sur navi et games (kb_options caps:super
  # dans config/hypr/hyprland.lua, pour tous les claviers).
  # 0x700000039 caps lock, 0x7000000e3 left gui (commande / super).
  # hidutil tourne a chaque just switch, et encore au boot
  # (activate-system). une deconnexion peut la perdre jusqu'au prochain
  # switch ou reboot. cmd+tab et cmd+espace partent aussi de caps lock.
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
    expose-animation-duration = 0.1;
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
    NSAutomaticWindowAnimationsEnabled = false;
    _HIHideMenuBar = false;
    # theme herbanium (velin clair) : mode clair fixe, pas de bascule auto le soir
    AppleInterfaceStyle = null;
    AppleInterfaceStyleSwitchesAutomatically = false;
  };

  # empeche la touche fn/globe et caps lock de basculer la disposition clavier
  system.defaults.hitoolbox.AppleFnUsageType = "Do Nothing";
  # accent graphite (-1) : neutre, ne tire pas sur le bronze du theme comme le ferait
  # l'orange. la surbrillance du texte prend surface1 de herbanium (velin, "Other").
  # pas d'option nix-darwin pour ces deux cles, d'ou CustomUserPreferences.
  system.defaults.CustomUserPreferences.NSGlobalDomain = {
    TISRomanSwitchState = 0;
    AppleAccentColor = -1;
    AppleHighlightColor = "0.827451 0.792157 0.701961 Other";
  };

  system.defaults.screencapture = {
    location = "~/Pictures/screenshots";
    type = "png";
  };
}
