# timon sur sommei : .dmg officiel (pas de cask homebrew). meme app que
# timon.nix, qui prend le .deb sur navi et games.
# le dmg est en apfs : undmg ne le lit pas, 7zz si. -snld garde les liens
# relatifs de node_modules/.bin, que 7zz jette sinon (la signature les compte).
# -sns- : sans lui, les xattrs com.apple.provenance deviennent des fichiers
# « nom:flux » dans le bundle, hors de sa signature.
# nix-darwin lie l'app dans /Applications/Nix Apps. la cli suit le lien
# jusqu'au bundle pour trouver node et l'orchestrateur.
# `just update` passe version et hash a la derniere release.
{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "timon";
  version = "0.1.9";

  src = fetchurl {
    url = "https://github.com/ai-timon/timon/releases/download/v${finalAttrs.version}/Timon-${finalAttrs.version}-arm64.dmg";
    hash = "sha256-m3BSpwd+nZaBDckvI0ZgS7BAeM8oVhYje+mTEAL6J50=";
  };

  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    runHook preUnpack
    7zz x -snld -sns- $src Timon.app
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  # le bundle est signe et notarise : ne rien reecrire dedans
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications $out/bin
    cp -R Timon.app $out/Applications/
    ln -s $out/Applications/Timon.app/Contents/cli/timon $out/bin/timon

    runHook postInstall
  '';

  meta = {
    description = "Self-hosted AI agent team running on your own machine";
    homepage = "https://timon-ai.com";
    license = lib.licenses.agpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "timon";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
