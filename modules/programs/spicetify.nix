# module: programs/spicetify
# spotify patched via spicetify-nix (theme + extensions)
{ pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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

    theme = {
      name = "Eva24";
      src = ../../config/spicetify/Eva24;
    };
    colorScheme = "eva24";
  };
}
