# see : lecteur de code natif (arbre, onglets, recherche, git, terminal), en go
# sans webview. hors nixpkgs, sans flake amont. tarball officiel : le build
# depuis les sources veut go 1.27 et telecharge libghostty-vt pendant le build.
# sommei prend le .app : see-darwin.nix.
# le binaire charge glib, gtk3, cairo, wayland, gstreamer... par dlopen (purego),
# sans NEEDED. un rpath serait plus propre, mais patchelf casse ce binaire go
# (ld.so segfault des qu'on touche au rpath) : on ne change que l'interpreteur,
# et les bibliotheques passent par LD_LIBRARY_PATH. effet de bord : les shells
# du terminal integre en heritent.
# see se relance lui-meme en arriere-plan, et cherche libghostty-vt.so a cote
# de son vrai binaire : le wrapper ne le gene pas.
# le store est en lecture seule : `just update` passe version et hash a la
# derniere release. la mise a jour integree de see reste, sans effet.
{
  lib,
  stdenv,
  fetchurl,
  atk,
  cairo,
  copyDesktopItems,
  fontconfig,
  gdk-pixbuf,
  glib,
  gst_all_1,
  gtk-layer-shell,
  gtk3,
  harfbuzz,
  libayatana-appindicator,
  libepoxy,
  libGL,
  libsecret,
  libx11,
  makeDesktopItem,
  pango,
  wayland,
  wrapGAppsHook3,
}:

let
  # charges par dlopen
  libs = [
    atk
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gst_all_1.gst-plugins-base # gstapp, gstvideo : apercu video
    gst_all_1.gstreamer
    gtk-layer-shell
    gtk3
    harfbuzz
    libayatana-appindicator
    libepoxy
    libGL
    libsecret
    libx11
    pango
    wayland
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "see";
  version = "0.3.10";

  src = fetchurl {
    url = "https://github.com/wibus-wee/see/releases/download/v${finalAttrs.version}/see-${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-ucyISWPH05L9+HutuAW2ZdDAZ2qcDZRWMqOPfd9QP2c=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    copyDesktopItems
    wrapGAppsHook3
  ];

  # wrapGAppsHook3 en tire les schemas gsettings (selecteur de fichiers gtk) et
  # GST_PLUGIN_SYSTEM_PATH_1_0 (codecs de l'apercu video)
  buildInputs = libs ++ [
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
  ];

  dontConfigure = true;
  dontBuild = true;
  # patchelf --shrink-rpath et strip reecriraient le binaire go
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/see
    install -m755 see libghostty-vt.so $out/libexec/see/
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/libexec/see/see
    install -Dm444 see.png $out/share/icons/hicolor/512x512/apps/see.png

    runHook postInstall
  '';

  dontWrapGApps = true;
  preFixup = ''
    makeWrapper $out/libexec/see/see $out/bin/see \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "see";
      desktopName = "See";
      comment = "Native code reader";
      exec = "see %U";
      icon = "see";
      startupWMClass = "see";
      categories = [ "Development" ];
    })
  ];

  meta = {
    description = "Native desktop app for reading source code";
    homepage = "https://github.com/wibus-wee/see";
    # depot sans licence
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "see";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
