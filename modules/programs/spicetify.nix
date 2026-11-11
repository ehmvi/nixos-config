# module: programs/spicetify
# spotify patched via spicetify-nix (theme + extensions)
{
  pkgs,
  inputs,
  theme,
  ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # spicetify veut les couleurs sans diese
  c = key: builtins.substring 1 6 theme.palette.${key};
in
{
  # le module spicetify-nix est importe ici : ce fichier est autonome
  imports = [ inputs.spicetify-nix.nixosModules.spicetify ];

  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      shuffle
    ];

    # structure tui dans user.css (aucune couleur), palette de theme.nix ici.
    # chaque cle devient une variable css --spice-<cle> ; colorScheme vaut "custom".
    theme = {
      name = "ramiel";
      src = ../../config/spicetify/ramiel;
    };
    customColorScheme = {
      # cles de spotify
      text = c "subtext1";
      subtext = c "subtext0";
      sidebar-text = c "overlay1";
      main = c "base";
      main-elevated = c "surface0";
      highlight = c "surface0";
      highlight-elevated = c "surface1";
      tab-active = c "surface1";
      sidebar = c "base";
      player = c "base";
      card = c "surface0";
      shadow = c "crust";
      selected-row = c "subtext1";
      button = c "mauve";
      button-active = c "teal";
      button-disabled = c "surface1";
      tab-bar = c "surface0";
      notification = c "blue";
      notification-error = c "red"; # le seul rouge : erreurs
      misc = c "surface1";
      # cles du theme (user.css)
      accent = c "mauve";
      accent-soft = c "teal";
      heading = c "text";
      link = c "teal";
      border = c "surface0";
      scrollbar = c "surface2";
      scrollbar-hover = c "overlay0";
    };
  };
}
