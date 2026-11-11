# module: desktop/sddm
# sddm en wayland (session hyprland via uwsm) + xserver pour le clavier et nvidia
{ pkgs, ... }:

{
  # greeter wayland (weston, le defaut du module). weston lit services.xserver.xkb
  # pour le layout. on garde xserver.enable : videoDrivers nvidia en depend, et
  # le module nvidia ne charge nvidia/nvidia_modeset/nvidia_drm que si xserver est actif.
  services.displayManager.sddm.wayland.enable = true;

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.settings.General.Numlock = "on"; # verr num actif sur sddm aussi
  # hyprland-uwsm.desktop du paquet hyprland (providedSessions), pas la session nue
  services.displayManager.defaultSession = "hyprland-uwsm";

  services.xserver.xkb = {
    layout = "us";
    variant = "";

    # qwerty-fr (accents sur altgr, qwerty us intact). absent de xkeyboard-config :
    # extraLayouts le greffe dans une copie et exporte XKB_CONFIG_ROOT, que lit hyprland.
    extraLayouts."us_qwerty-fr" = {
      description = "qwerty us avec les symboles francais sur altgr";
      languages = [
        "eng"
        "fra"
      ];
      symbolsFile = "${pkgs.qwerty-fr}/share/X11/xkb/symbols/us_qwerty-fr";
    };
  };
}
