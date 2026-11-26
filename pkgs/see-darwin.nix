# see sur sommei : tarball .app officiel (pas de cask homebrew). meme app que
# see.nix, qui prend le tarball linux sur navi et games.
# nix-darwin lie l'app dans /Applications/Nix Apps. la commande `see` est un
# script, pas un lien : le binaire cherche libghostty-vt.dylib par rapport au
# chemin qui l'a lance, donc il doit etre appele depuis le bundle.
# `just update` passe version et hash a la derniere release.
{
  lib,
  stdenvNoCC,
  fetchurl,
  runtimeShell,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "see";
  version = "0.3.10";

  src = fetchurl {
    url = "https://github.com/wibus-wee/see/releases/download/v${finalAttrs.version}/see-${finalAttrs.version}-darwin-arm64.tar.gz";
    hash = "sha256-fTKTy/zsZ8I0Oi1qdxVMgcndsjYPXmAkOXg6tigaFRE=";
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  # bundle signe ad hoc : ne rien reecrire dedans
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications $out/bin
    cp -R See.app $out/Applications/
    cat > $out/bin/see <<EOF
    #!${runtimeShell}
    exec "$out/Applications/See.app/Contents/MacOS/See" "\$@"
    EOF
    chmod +x $out/bin/see

    runHook postInstall
  '';

  meta = {
    description = "Native desktop app for reading source code";
    homepage = "https://github.com/wibus-wee/see";
    # depot sans licence
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "see";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
