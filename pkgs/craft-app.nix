# une app de la suite craft (anicraft, photocraft...) sur navi et games :
# tarball linux officiel (hors nixpkgs), meme forme pour toutes : bin/<app>,
# bin/<app>-cli et share/ (entree de bureau, icones, types mime).
# craft-app-darwin.nix prend le .dmg sur sommei. version et hash viennent de
# craft-apps.json (modules/programs/craft.nix), `just bump-craft` les avance.
# les apps chargent leur pile graphique par dlopen (wayland, x11, egl,
# vulkan, dbus), d'ou runtimeDependencies : une seule liste couvre les 14.
# filmcraft charge aussi libva et libcuda : driverLink ajoute
# /run/opengl-driver/lib au rpath, ou nixos met le pilote.
{
  lib,
  stdenv,
  fetchurl,
  addDriverRunpath,
  alsa-lib,
  autoPatchelfHook,
  dbus,
  fontconfig,
  libGL,
  libva,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrender,
  vulkan-loader,
  wayland,
  # craft-apps.json
  pname,
  repo,
  version,
  hash,
}:

stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/v${version}/${pname}-${version}-linux-x86_64.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  # alsa : lie directement par les apps audio (soundcraft, filmcraft...)
  buildInputs = [
    alsa-lib
    stdenv.cc.cc.lib
  ];

  # getLib : la sortie par defaut de fontconfig est -bin, sans la bibliotheque
  runtimeDependencies = [
    addDriverRunpath.driverLink
  ]
  ++ map lib.getLib [
    dbus
    fontconfig
    libGL
    libva
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrender
    vulkan-loader
    wayland
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r bin share $out/

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/${repo}";
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
