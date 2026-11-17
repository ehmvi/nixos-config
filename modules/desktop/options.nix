# module: desktop/options
# options fyrr.* propres a ce depot, lues par les autres modules desktop
{ lib, ... }:

{
  options.fyrr.wayle.configFile = lib.mkOption {
    type = lib.types.path;
    description = "config.toml de wayle propre au host (runtime.toml reste inscriptible par wayle)";
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
