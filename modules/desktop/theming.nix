# module: desktop/theming
# gtk et qt sombres aux couleurs de theme.nix, curseur bibata, icones breeze-dark.
# les couleurs viennent des fichiers natifs config/gtk/ et config/kde/ (theme.render).
{
  lib,
  pkgs,
  theme,
  username,
  ...
}:

let
  # curseur : bibata modern ice (blanc, coins arrondis). meme nom et taille
  # que XCURSOR_THEME / HYPRCURSOR_THEME dans hyprland.lua
  cursorTheme = "Bibata-Modern-Ice";
  cursorSize = 24;
  gtkCss = theme.render ../../config/gtk/gtk.css;
in
{
  environment.systemPackages = with pkgs; [
    bibata-cursors
    adw-gtk3 # theme gtk3 qui suit libadwaita et lit ses couleurs nommees (gtk.css)
    kdePackages.breeze-icons # breeze-dark, pour gtk comme pour qt
    kdePackages.breeze # style qt6 des applis kde
  ];

  # gtk : reglages lus par gtk (gsettings) et par xdg-desktop-portal-gtk, qui
  # transmet color-scheme aux applis electron, a brave et a libadwaita.
  # base systeme (dconf) : rien dans ~/.config, un `gsettings set` passe devant.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "breeze-dark";
        cursor-theme = cursorTheme;
        cursor-size = lib.gvariant.mkInt32 cursorSize; # schema : entier 32 bits
        # police tui, legere, comme ramiel. inter pour les documents
        font-name = "JetBrainsMono Nerd Font Light 10";
        monospace-font-name = "JetBrainsMono Nerd Font 10";
        document-font-name = "Inter 10";
      };
    }
  ];

  # qt : theme de plateforme kde (plasma-integration). les applis kde lisent alors les
  # couleurs, la police, les icones, le style et le terminal dans kdeglobals.
  # pas de qt.style : il installe aussi breeze pour qt5, et toutes les kf5 avec (~700 mo).
  # le style breeze qt6 (paquet plus haut) est choisi par widgetStyle dans kdeglobals.
  qt = {
    enable = true;
    platformTheme = "kde";
  };
  # dans /etc/xdg et pas dans ~/.config : les applis kde reecrivent ~/.config/kdeglobals
  # (dialogue de fichiers...), un lien hjem y casserait
  environment.etc."xdg/kdeglobals".text = theme.render ../../config/kde/kdeglobals;

  # gtk.css : couleurs nommees pour gtk3 (adw-gtk3) et gtk4 (libadwaita).
  # gtk4 recoit en plus les variables css de libadwaita 1.6+
  hjem.users.${username}.files = {
    ".config/gtk-3.0/gtk.css".text = gtkCss;
    ".config/gtk-4.0/gtk.css".text = gtkCss + theme.render ../../config/gtk/gtk4.css;
  };
}
