# module: programs/godot-android
# jdk 17 et sdk android pour exporter un projet godot 4.5 vers le meta quest 3.
# importe seulement par sommei.
#
# godot 4.5.1-stable (platform/android/java/app/config.gradle) epingle
# ndk 28.1.13356709, build-tools 35.0.0 et platform android-35.
# ndk 23.2.8568313 + build-tools 34 + android-34, c est godot 4.4 : le gradle
# de 4.5 echoue si c est la seule chose d installee.
#
# les chemins du store bougent a chaque rebuild. environment.etc garde des
# liens fixes, a coller dans l editeur (export > android) :
#   java sdk path    /etc/godot/jdk
#   android sdk path /etc/godot/android-sdk
# le ndk est /etc/godot/android-sdk/ndk/28.1.13356709
#
# fish lit JAVA_HOME / ANDROID_HOME / ANDROID_SDK_ROOT via environment.variables
# (nix-darwin les pose dans /etc/fish/nixos-env-preinit.fish).
# sommei n utilise que fish. nushell reste le shell des hosts nixos.
{ pkgs, ... }:

let
  # cmdline-tools 22.0 a une archive macos aarch64. "latest" dans le depot
  # du lock pointe deja dessus ; on l epingle pour que le lien cmdline-tools/latest
  # reste aligne.
  cmdLineToolsVersion = "22.0";
  # seule version de platform-tools dans le repo.json de ce nixpkgs.
  # godot 4.5 demande platform-tools >= 35.
  platformToolsVersion = "37.0.1";
  buildToolsVersion = "35.0.0";
  platformVersion = "35";
  ndkVersion = "28.1.13356709";

  # licence android acceptee ici seulement. nixpkgs.config.android_sdk.accept_license
  # n est pas pose pour le reste du systeme. allowUnfree est deja global.
  androidEnv = pkgs.androidenv.override { licenseAccepted = true; };

  androidComposition = androidEnv.composeAndroidPackages {
    inherit cmdLineToolsVersion platformToolsVersion;
    buildToolsVersions = [ buildToolsVersion ];
    platformVersions = [ platformVersion ];
    includeEmulator = false;
    includeSystemImages = false;
    includeSources = false;
    includeNDK = true;
    ndkVersions = [ ndkVersion ];
    # defaut true sur darwin. cmake 3.10.2 est x86_64 only, et l export 4.5
    # ne l appelle pas.
    includeCmake = false;
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
  };

  # racine que godot attend : le dossier qui contient platform-tools/adb,
  # pas le prefixe nix (bin/ + libexec/). cmdline-tools arrive en
  # cmdline-tools/22.0 ; on ajoute latest, que la doc et detect.py cherchent.
  androidSdk = pkgs.runCommand "godot-android-sdk" { } ''
    sdk="${androidComposition.androidsdk}/libexec/android-sdk"
    mkdir -p "$out"
    for item in "$sdk"/*; do
      name="$(basename "$item")"
      if [ "$name" = "cmdline-tools" ]; then
        mkdir -p "$out/cmdline-tools"
        for tool in "$item"/*; do
          ln -s "$tool" "$out/cmdline-tools/$(basename "$tool")"
        done
        if [ ! -e "$out/cmdline-tools/latest" ]; then
          ln -s ${cmdLineToolsVersion} "$out/cmdline-tools/latest"
        fi
      else
        ln -s "$item" "$out/$name"
      fi
    done
  '';

  # sur aarch64-darwin, pkgs.jdk17 est le binaire zulu 17 (pas une compile).
  jdk = pkgs.jdk17;
  godot = pkgs.godot_4_5;
in
{
  environment.systemPackages = [
    jdk
    godot
    # adb et sdkmanager sur le PATH. le dossier a coller dans godot est androidSdk.
    androidComposition.androidsdk
  ];

  environment.etc."godot/jdk".source = jdk;
  environment.etc."godot/android-sdk".source = androidSdk;

  environment.variables = {
    JAVA_HOME = "/etc/godot/jdk";
    ANDROID_HOME = "/etc/godot/android-sdk";
    ANDROID_SDK_ROOT = "/etc/godot/android-sdk";
  };

  # homebrew (cleanup) tourne avant postActivation : le cask godot est retire
  # avant ce lien. types.lines concatene avec le script zen du host.
  system.activationScripts.postActivation.text = ''
    # nixpkgs depose le bundle dans GodotMono.app meme sans le module mono.
    ln -sfn ${godot}/Applications/GodotMono.app /Applications/Godot.app
  '';
}
