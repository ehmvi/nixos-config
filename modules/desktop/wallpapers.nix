# fonds evangelion par defaut (github.com/Aleph1-9012/Evangelion), epingles sur un commit precis.
# nix ne telecharge que ces 2 images, et verifie leur contenu grace au hash.
# pas un module : options.nix l'importe pour les valeurs par defaut de fyrr.wallpapers
{ fetchurl }:

{
  lockWallpaper = fetchurl {
    url = "https://raw.githubusercontent.com/Aleph1-9012/Evangelion/fb785c3009a9346173d4b893d6aa36dd22052335/wallpapers/Ayanami-wall.png";
    hash = "sha256-GdWym23O1irCSb62XTq2EU+9NnhAwE/JW9hVjeMe8M4=";
  };
  desktopWallpaper = fetchurl {
    url = "https://raw.githubusercontent.com/Aleph1-9012/Evangelion/fb785c3009a9346173d4b893d6aa36dd22052335/wallpapers/Ramiel-wall.png";
    hash = "sha256-OnyTyFxrUVyGyjyG6ZEqdUvIFkDhb3lpSXChBhRrlUI=";
  };
}
