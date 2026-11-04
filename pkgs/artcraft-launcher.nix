# artcraft launcher : binaire linux officiel (hors nixpkgs).
# le binaire charge wayland, egl, vulkan, x11 et dbus par dlopen, d'ou
# runtimeDependencies : le rpath suffit, et un LD_LIBRARY_PATH passerait aux
# apps que le lanceur demarre.
# le store est en lecture seule : `just update` passe version et hash a la
# derniere release, et son auto-update interne echoue sans dommage.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dbus,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "artcraft-launcher";
  version = "0.14.0";

  src = fetchurl {
    url = "https://github.com/storytold/craft-launcher/releases/download/v${finalAttrs.version}/artcraft-launcher-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-aDltkY+tkKuvMuE5gK3kNCEK6xJRAFyY3rqfLvnDPKo=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  runtimeDependencies = [
    dbus
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
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
    description = "Installs, updates and opens the Craft App Suite";
    homepage = "https://github.com/storytold/craft-launcher";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "artcraft-launcher";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
