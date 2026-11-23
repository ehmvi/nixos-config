# module: desktop/options
# options fyrr.* propres a ce depot, lues par les autres modules desktop
{ lib, pkgs, ... }:

let
  defaultWallpapers = import ./wallpapers.nix { inherit (pkgs) fetchurl; };
in
{
  options.fyrr.wayle.configFile = lib.mkOption {
    type = lib.types.path;
    description = "config.toml de wayle propre au host (runtime.toml reste inscriptible par wayle)";
  };

  options.fyrr.wallpapers = {
    desktop = lib.mkOption {
      type = lib.types.path;
      default = defaultWallpapers.desktopWallpaper;
      description = "fond d'ecran du bureau (wayle et ~/.config/hypr/wallpaper.png)";
    };
    lock = lib.mkOption {
      type = lib.types.path;
      default = defaultWallpapers.lockWallpaper;
      description = "fond de l'ecran de verrouillage et de connexion (hyprlock et sddm)";
    };
  };

  options.fyrr.hyprlock = {
    battery = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "BAT0";
      description = "batterie affichee par hyprlock (nom dans /sys/class/power_supply). null = pas de label";
    };
  };
}
