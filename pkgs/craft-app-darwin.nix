# une app de la suite craft sur sommei : .dmg universel officiel (pas de
# cask homebrew). meme source que craft-app.nix, qui prend le tarball linux.
# le dmg est en hfs : 7zz le lit. -snld garde les liens relatifs du bundle,
# -sns- evite que les xattrs deviennent des fichiers hors de la signature.
# le volume contient « <App> <version>/<App>.app » et un lien Applications
# vers /Applications : find ne suit pas les liens et ne garde que le bundle.
# nix-darwin lie l'app dans /Applications/Nix Apps.
{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
  # craft-apps.json
  pname,
  repo,
  version,
  hash,
}:

stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/v${version}/${pname}-${version}-macos-universal.dmg";
    inherit hash;
  };

  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    runHook preUnpack
    mkdir dmg
    7zz x -snld -sns- -odmg $src
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;
  # le bundle est signe et notarise : ne rien reecrire dedans
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mapfile -t apps < <(find dmg -mindepth 2 -maxdepth 2 -type d -name '*.app')
    if [ "''${#apps[@]}" -ne 1 ]; then
      echo "il faut un seul .app dans le dmg, trouve : ''${apps[*]}" >&2
      exit 1
    fi
    mkdir -p $out/Applications
    cp -R "''${apps[0]}" $out/Applications/

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/${repo}";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
