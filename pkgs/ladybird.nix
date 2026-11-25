# ladybird : navigateur independant (moteur maison). paquet .deb officiel
# ubuntu 24.04 (apt.ladybird.org) : celui de nixpkgs reste sur un snapshot
# pre-alpha, et le .deb 26.04 casse sur wayland avec qt 6.12 de nixpkgs
# (desaccord de revision sur QWaylandApplication). le .deb 24.04 embarque son
# propre qt 6.11.3 et ses plugins : on isole QT_PLUGIN_PATH dessus et on passe
# par xdgdesktopportal pour suivre le theme sombre du bureau sans melanger les
# plugins qt 6.12 du systeme. sommei prend le .dmg officiel : ladybird-darwin.nix.
# le nom explicite dans fetchurl evite le tilde (~) du nom de fichier amont,
# interdit dans le store nix.
# les bibliotheques embarquees restent sous $out/lib/ladybird/lib pour ne pas
# polluer $out/lib : les binaires les trouvent via $ORIGIN/../lib, ainsi que
# libexec/ et share/Lagom/ en relatif.
# ffmpeg de nixpkgs en runtimeDependencies fournit libavcodec.so.63 (dlopen par
# VideoDecoderServer/MediaServer pour le decodage h264/h265).
# `just update` avance version et hash via `just bump-ladybird`.
{
  lib,
  stdenv,
  fetchurl,
  addDriverRunpath,
  autoPatchelfHook,
  dpkg,
  ffmpeg,
  glib,
  libdrm,
  libglvnd,
  libpulseaudio,
  libx11,
  libxcb,
  libxcb-cursor,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-util,
  libxcb-wm,
  libxkbcommon,
  makeShellWrapper,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ladybird";
  version = "2026.47.8";

  src = fetchurl {
    name = "ladybird-${finalAttrs.version}-amd64.deb";
    url = "https://apt.ladybird.org/pool/main/l/ladybird/ladybird_${finalAttrs.version}-1~ubuntu24.04_amd64.deb";
    hash = "sha256-9FvU+CL0Xr8cqKjARNQqnamfqA+rqwm4Rd9z6o0dZyY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeShellWrapper
  ];

  buildInputs = [
    glib
    libdrm
    libglvnd
    libpulseaudio
    libx11
    libxcb
    libxcb-cursor
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-util
    libxcb-wm
    libxkbcommon
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
  ];

  # charges par dlopen : pilotes gpu (/run/opengl-driver/lib) et ffmpeg systeme
  # (libavcodec.so.63 pour h264/h265, absent du ffmpeg lgpl embarque)
  runtimeDependencies = [
    addDriverRunpath.driverLink
    (lib.getLib ffmpeg)
    libglvnd
  ];

  # entrees .note.dlopen optionnelles de sdl3 (manettes) lie statiquement
  autoPatchelfIgnoreMissingDeps = [
    "libGLES_CM.so.1"
    "libsteam_api.so"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ladybird $out/bin $out/share
    cp -r opt/ladybird/. $out/lib/ladybird/
    cp -r usr/share/. $out/share/

    substituteInPlace $out/share/applications/org.ladybird.Ladybird.desktop \
      --replace-fail "/opt/ladybird/bin/Ladybird" "ladybird"
    substituteInPlace $out/share/dbus-1/services/org.ladybird.Ladybird.service \
      --replace-fail "/opt/ladybird/bin/Ladybird" "$out/bin/ladybird"

    runHook postInstall
  '';

  # QT_PLUGIN_PATH force les plugins qt 6.11.3 embarques : ceux de qt 6.12 du
  # systeme feraient planter le chargement. xdgdesktopportal lit color-scheme
  # et ouvre les dialogues de fichiers natifs.
  preFixup = ''
    addAutoPatchelfSearchPath "$out/lib/ladybird/lib"
    makeShellWrapper $out/lib/ladybird/bin/Ladybird $out/bin/ladybird \
      --set QT_PLUGIN_PATH "$out/lib/ladybird/Qt6/plugins" \
      --set QT_QPA_PLATFORMTHEME xdgdesktopportal \
      --unset QML2_IMPORT_PATH \
      --unset QML_IMPORT_PATH
  '';

  meta = {
    description = "Truly independent web browser";
    homepage = "https://ladybird.org";
    license = lib.licenses.bsd2;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ladybird";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
