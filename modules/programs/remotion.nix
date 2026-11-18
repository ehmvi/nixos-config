# module: programs/remotion
# videos en react : node + ffmpeg, remotion s installe par projet (npx), comme sur sommei
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs_22
    ffmpeg
  ];

  # remotion telecharge chrome-headless-shell et son compositor (rust + ffmpeg)
  # en binaires precompiles pour glibc generique. sans nix-ld ils ne trouvent
  # ni le chargeur ni leurs bibliotheques. la liste couvre chrome headless,
  # les bibliotheques par defaut de nix-ld couvrent le reste (libstdc++, zlib...).
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      glib
      libdrm
      libgbm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libxshmfence
    ];
  };
}
