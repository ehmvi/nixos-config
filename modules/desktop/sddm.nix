# module: desktop/sddm
# sddm en wayland (session hyprland via uwsm) + xserver pour le clavier et nvidia
{
  config,
  pkgs,
  theme,
  ...
}:

let
  # meme fond que hyprlock (option fyrr.wallpapers.lock, ayanami par defaut) :
  # les deux ecrans de mot de passe se ressemblent, le bureau a son propre fond
  lockWallpaper = config.fyrr.wallpapers.lock;

  # where-is-my-sddm-theme : un seul champ de mot de passe, qt6, et pour toute
  # dependance qt5compat + qtsvg. sddm-astronaut tire qtmultimedia et
  # qtvirtualkeyboard pour des fonds video dont on ne se sert pas.
  # l'utilisateur et la session sont ceux de la derniere connexion (f2 / f3 pour changer, f1 aide)
  sddmTheme = pkgs.where-is-my-sddm-theme.override {
    themeConfig.General = {
      background = "${lockWallpaper}";
      backgroundMode = "aspect";
      # derriere l'image, et a sa place si elle ne charge pas
      backgroundFill = theme.palette.base;
      basicTextColor = theme.palette.text;
      passwordTextColor = theme.accentHex;
      passwordCursorColor = theme.accentHex;
      passwordInputBackground = theme.palette.base;
      passwordFontSize = 32;
      passwordInputWidth = 0.3;
      font = "JetBrainsMono Nerd Font";
    };
  };
in
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

  # chemin absolu : le theme n'a pas besoin d'etre dans systemPackages.
  # extraPackages ajoute ses modules qml (qt5compat, qtsvg) au wrapper de sddm
  services.displayManager.sddm.theme = "${sddmTheme}/share/sddm/themes/where_is_my_sddm_theme";
  services.displayManager.sddm.extraPackages = [ sddmTheme ];

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
