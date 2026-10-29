# module: desktop/sddm
# sddm en wayland (session hyprland via uwsm) + xserver pour le clavier et nvidia
_:

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
  };
}
