# timon : equipe d'agents ia auto-hebergee (orchestrateur + clients). .deb
# officiel, hors nixpkgs, sans flake amont. sommei prend le .dmg : timon-darwin.nix.
# le paquet porte le client electron (timon-desktop) et la cli (timon). les deux
# lancent l'orchestrateur avec resources/node/node. patchelf casse ce node
# (segfault au lancement), donc on le remplace par le nodejs_22 de nixpkgs : meme
# abi pour les modules natifs (better-sqlite3, node-pty). une copie, pas un lien :
# l'app copie le paquet dans ~/.timon/desktop-runtime pour son service, saute les
# liens absolus, et refuse un node qui sort du paquet. la racine gc de cette
# copie est dans modules/programs/timon.nix.
# les agents (claude, codex...) viennent du PATH de l'utilisateur. node y est
# ajoute : timon doctor bloque sans lui.
# le store est en lecture seule : `just update` passe version et hash a la
# derniere release. la banniere de mise a jour de timon reste, sans effet.
{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  copyDesktopItems,
  cups,
  dbus,
  dpkg,
  expat,
  glib,
  gtk3,
  libdrm,
  libGL,
  libgbm,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxtst,
  makeDesktopItem,
  makeShellWrapper,
  nspr,
  nodejs_22,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  wrapGAppsHook3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "timon";
  version = "0.1.9";

  src = fetchurl {
    url = "https://github.com/ai-timon/timon/releases/download/v${finalAttrs.version}/timon-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-75M311xU5mhrb3Fpn8vIGJe9hl5TZL2Ss/l2LwY3onQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    dpkg
    makeShellWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libsecret
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxtst
    nspr
    nss
    pango
    stdenv.cc.cc.lib
  ];

  # charges par dlopen
  runtimeDependencies = [
    libGL
    libnotify
    pipewire
    systemd
    vulkan-loader
    wayland
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  dontWrapGApps = true;
  # lance a la main dans postFixup : le node de nixpkgs arrive apres, deja lie
  # (autoPatchelf lui retirerait son rpath)
  dontAutoPatchelf = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    cp -r opt/Timon $out/libexec/timon
    rm $out/libexec/timon/resources/node/node
    install -Dm444 usr/share/icons/hicolor/512x512/apps/timon-desktop.png \
      $out/share/icons/hicolor/512x512/apps/timon-desktop.png

    runHook postInstall
  '';

  # ELECTRON_RUN_AS_NODE : herite d'un terminal ouvert par une autre app electron,
  # electron tournerait en simple node, sans fenetre ni message.
  # le service que l'app installe garde le PATH de l'app, donc node aussi.
  preFixup = ''
    makeShellWrapper $out/libexec/timon/cli/timon $out/bin/timon \
      --prefix PATH : ${lib.makeBinPath [ nodejs_22 ]}
    makeShellWrapper $out/libexec/timon/timon-desktop $out/bin/timon-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_22 ]} \
      --unset ELECTRON_RUN_AS_NODE \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  postFixup = ''
    autoPatchelf -- $out
    install -m555 ${nodejs_22}/bin/node $out/libexec/timon/resources/node/node
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "timon-desktop";
      desktopName = "Timon";
      comment = "Self-hosted AI agent team";
      exec = "timon-desktop %U";
      icon = "timon-desktop";
      startupWMClass = "timon-desktop";
      categories = [ "Development" ];
    })
  ];

  meta = {
    description = "Self-hosted AI agent team running on your own machine";
    homepage = "https://timon-ai.com";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "timon";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
