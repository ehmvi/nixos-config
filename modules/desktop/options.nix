# module: desktop/options
# options fyrr.* propres a ce depot, lues par les autres modules desktop
{ lib, ... }:

{
  options.fyrr.wayle.configFile = lib.mkOption {
    type = lib.types.path;
    description = "config.toml de wayle propre au host (runtime.toml reste inscriptible par wayle)";
  };

  options.fyrr.hyprlock = {
    layouts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "us"
        "fr"
      ];
      description = "noms courts des dispositions, dans l'ordre de kb_layout (hyprland.lua). vide = pas de label";
    };
    battery = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "BAT0";
      description = "batterie affichee par hyprlock (nom dans /sys/class/power_supply). null = pas de label";
    };
  };
}
