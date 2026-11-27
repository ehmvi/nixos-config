# ladybird sur sommei : .dmg arm64 officiel (download.ladybird.org, pas de cask
# homebrew). meme version que ladybird.nix, qui prend le .deb sur navi et games.
# le dmg est en apfs : undmg ne le lit pas, 7zz si. -snld garde les liens
# relatifs du bundle, -sns- evite que les xattrs deviennent des fichiers
# « nom:flux » hors de la signature.
# nix-darwin lie le bundle dans /Applications/Nix Apps.
# `just update` avance version et hash via `just bump-ladybird`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ladybird";
  version = "2026.48.0";

  src = fetchurl {
    url = "https://download.ladybird.org/macos/${finalAttrs.version}/ladybird-${finalAttrs.version}-macOS-arm64.dmg";
    hash = "sha256-QHGIWZ9HW7RoNg/lKicgxbJOybPjWPfBfUE0f1BLrLY=";
  };

  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    runHook preUnpack
    7zz x -snld -sns- $src Ladybird.app
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  # le bundle est signe et notarise : ne rien reecrire dedans
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications $out/bin
    cp -R Ladybird.app $out/Applications/
    ln -s $out/Applications/Ladybird.app/Contents/MacOS/Ladybird $out/bin/ladybird

    runHook postInstall
  '';

  meta = {
    description = "Truly independent web browser";
    homepage = "https://ladybird.org";
    license = lib.licenses.bsd2;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "ladybird";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
