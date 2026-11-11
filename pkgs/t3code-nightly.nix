# t3 code nightly : .deb officiel. nixpkgs ne suit que les releases stables, et
# une nightly change trop souvent pour recalculer le hash des deps pnpm.
# installable a cote de la stable (modules/programs/apps.nix) : autre binaire,
# autre .desktop, autre icone. la nightly a ses propres donnees :
# - T3CODE_HOME : meme etat = verrou server-owner.sqlite, et ses migrations
#   passeraient devant celles de la stable.
# - profil electron : le nom est code en dur (t3code-v2), et le meme profil
#   ferait quitter la 2e instance. XDG_CONFIG_HOME le changerait aussi, mais
#   les agents en heriteraient et perdraient ~/.config (gh, git...). d'ou le sed,
#   a longueur egale pour garder les offsets de l'asar.
# le store est en lecture seule : `just update` passe version et hash a la
# derniere nightly, et l'auto-update interne est coupe.
{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  claude-code,
  copyDesktopItems,
  cups,
  dbus,
  dpkg,
  expat,
  gh,
  git,
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
  makeDesktopItem,
  makeShellWrapper,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  wrapGAppsHook3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "t3code-nightly";
  version = "0.1.9-nightly.20261111.4515";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${finalAttrs.version}/T3-Code-${finalAttrs.version}-amd64.deb";
    hash = "sha256-FF1UpDFWvqfLkt0Y2zOVmd3uB68NhNQ4Yy0aVOUAaaU=";
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
    nspr
    nss
    pango
    stdenv.cc.cc.lib
  ];

  # prebuilds musl du module ffi-rs : jamais charges sur glibc
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

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

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    cp -r "opt/T3 Code (Nightly)" $out/libexec/t3code-nightly

    # le nom doit rester la, sinon la nightly partagerait le profil de la stable
    asar=$out/libexec/t3code-nightly/resources/app.asar
    LC_ALL=C grep -aq 't3code-v2' "$asar"
    LC_ALL=C sed -i 's/t3code-v2/t3nightly/g' "$asar"

    for icon in usr/share/icons/hicolor/*/apps/t3code.png; do
      size=$(basename "$(dirname "$(dirname "$icon")")")
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/t3code-nightly.png"
    done

    runHook postInstall
  '';

  # meme PATH que la stable pour les agents : claude code a la place de codex,
  # gh et git restent. T3CODE_DESKTOP_LAUNCHER_PATH : sinon les liens t3code://
  # lanceraient l'electron nu, donc sans T3CODE_HOME, sur les donnees de la stable.
  # ELECTRON_RUN_AS_NODE : herite si on lance depuis un terminal de la stable,
  # et electron y tournerait en simple node, sans fenetre ni message.
  preFixup = ''
    makeShellWrapper $out/libexec/t3code-nightly/t3code $out/bin/t3code-nightly \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          claude-code
          gh
          git
        ]
      } \
      --run 'export T3CODE_HOME="$HOME/.t3-nightly"' \
      --unset ELECTRON_RUN_AS_NODE \
      --set T3CODE_DISABLE_AUTO_UPDATE 1 \
      --set T3CODE_DESKTOP_LAUNCHER_PATH $out/bin/t3code-nightly \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "t3code-nightly";
      desktopName = "T3 Code (Nightly)";
      comment = "Desktop GUI for coding agents";
      exec = "t3code-nightly %U";
      icon = "t3code-nightly";
      startupWMClass = "com.t3tools.T3Code";
      categories = [ "Development" ];
    })
  ];

  meta = {
    description = "Desktop GUI for coding agents (nightly)";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code-nightly";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
