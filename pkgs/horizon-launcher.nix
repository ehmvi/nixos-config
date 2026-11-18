# horizon launcher : binaire linux officiel (hors nixpkgs).
# horizon reecrit minecraft java 26.3 en rust. le lanceur telecharge le jeu,
# le prepare depuis la copie de minecraft 26.3 du joueur (avec le runtime java
# de mojang), puis le lance. ces binaires telecharges supposent une distro
# classique : l'environnement fhs leur donne /lib64/ld-linux et les
# bibliotheques. la liste reprend celle du paquet du flake amont, qui compile
# le lanceur depuis tout le monorepo (pres de 1 go) : ici, pas de compilation.
# le store est en lecture seule : l'auto-update du lanceur est coupe, et
# `just update` passe version et hash a la derniere release `launcher@`.
# les versions du jeu se mettent a jour dans le lanceur, sous ~/.local/share.
{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  makeDesktopItem,
}:

let
  pname = "horizon-launcher";

  unwrapped = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "${pname}-unwrapped";
    version = "0.2.71";

    src = fetchurl {
      url = "https://github.com/horizon-rust/horizon/releases/download/launcher@${finalAttrs.version}/horizon-launcher-linux-x86_64.tar.gz";
      hash = "sha256-xdIkqSFC9vtHapGgNOoGSzTjwziE3YaLQaFBBBGULms=";
    };

    # l'archive ne contient que le binaire, sans dossier
    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;
    # le fhs fournit l'interpreteur et les bibliotheques : rien a patcher
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 horizon-launcher $out/bin/horizon-launcher
      runHook postInstall
    '';
  });

  # icone du depot amont, epinglee au commit de launcher@0.2.69
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/horizon-rust/horizon/4626921895df51521be64d485ee763412de2917c/packaging/icons/hicolor/scalable/apps/horizon.svg";
    hash = "sha256-KowIca6KH8TTvkfIzhh+5UEdlVPaJBQR3dfnXGE3PrM=";
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Horizon";
    genericName = "Game launcher";
    comment = "Install, prepare and play Horizon, Minecraft: Java Edition rewritten in Rust";
    exec = pname;
    icon = "horizon";
    categories = [ "Game" ];
    startupWMClass = "horizon-launcher";
  };
in
buildFHSEnv {
  inherit pname;
  inherit (unwrapped) version;

  targetPkgs =
    pkgs: with pkgs; [
      # fenetre, rendu : vulkan, wayland, x11
      vulkan-loader
      libglvnd
      wayland
      libxkbcommon
      libx11
      libxcb
      libxcursor
      libxext
      libxi
      libxrandr
      libxrender
      libxxf86vm

      # son, manettes (udev), et leurs en-tetes pour les mods natifs
      udev
      udev.dev
      alsa-lib
      alsa-lib.dev

      # bureau, polices, trousseau
      fontconfig
      freetype
      dbus
      xdg-utils
      procps

      # runtime java de mojang (horizon-prepare)
      zlib
      libxtst

      gamemode

      # compilation des mods natifs
      gcc
      glibc.dev
      pkg-config
    ];

  runScript = "${unwrapped}/bin/horizon-launcher";

  # le lanceur ouvre la socket de controle du jeu sous XDG_RUNTIME_DIR (repli
  # /tmp) et refuse tout dossier parent qui n'est ni a root ni a l'utilisateur.
  # dans le namespace de bwrap, root n'est pas mappe : /run, /run/user et /tmp
  # y appartiennent a nobody (65534), et le lancement echoue sur
  # « bind holder control socket: permission denied ». on remonte le runtime
  # dir sous la racine tmpfs de bwrap, qui appartient a l'utilisateur.
  extraBwrapArgs = [
    ''--bind "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" /xdg-runtime''
    "--setenv XDG_RUNTIME_DIR /xdg-runtime"
  ];

  profile = ''
    export HORIZON_LAUNCHER_NO_SELF_UPDATE=1
    export HORIZON_LAUNCHER_DESKTOP_EXEC="''${HORIZON_LAUNCHER_DESKTOP_EXEC:-${pname}}"
    export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:''${PKG_CONFIG_PATH:-}"
  '';

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/${pname}.desktop -t $out/share/applications
    install -Dm444 ${icon} $out/share/icons/hicolor/scalable/apps/horizon.svg
  '';

  passthru = { inherit unwrapped; };

  meta = {
    description = "Launcher for Horizon, Minecraft: Java Edition rewritten in Rust";
    homepage = "https://playhorizon.dev";
    license = lib.licenses.lgpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
