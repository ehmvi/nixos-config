# sm64coopdx : binaire linux officiel.
# le paquet nixpkgs (meme version) compile depuis les sources et exige la rom
# us au build, via requireFile. cette release est deja compilee : pas de rom
# ici. au premier lancement, le jeu demande la rom us et la copie dans
# ~/.local/share/sm64coopdx/baserom.us.z64 (SDL_GetPrefPath).
# l updater est retire : le store est en lecture seule.
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  SDL2,
  libGL,
  curl,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sm64coopdx";
  version = "1.5.1";

  src = fetchurl {
    url = "https://github.com/coop-deluxe/sm64coopdx/releases/download/v${finalAttrs.version}/sm64coopdx_Linux.zip";
    hash = "sha256-Qin4L8Q5Xnj68ZLJEP/PzB1w9ZpVjK3w9jrlSJAfpfU=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    SDL2
    libGL
    curl
    zlib
    stdenv.cc.cc.lib
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sm64coopdx
    unzip -q $src -d $out/share/sm64coopdx
    rm -f $out/share/sm64coopdx/coopdx_updater
    chmod +x $out/share/sm64coopdx/sm64coopdx

    # le binaire charge dynos/lang/mods et libdiscord depuis son dossier
    mkdir -p $out/bin
    makeWrapper $out/share/sm64coopdx/sm64coopdx $out/bin/sm64coopdx \
      --chdir $out/share/sm64coopdx

    runHook postInstall
  '';

  meta = {
    description = "Super Mario 64 coop deluxe";
    homepage = "https://github.com/coop-deluxe/sm64coopdx";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sm64coopdx";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
