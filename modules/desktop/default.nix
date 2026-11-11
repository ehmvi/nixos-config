# module: desktop
# groups shared graphical modules
{ ... }:

{
  imports = [
    ./hyprland.nix
    ./sddm.nix
    ./audio.nix
    ./fonts.nix
    ./theming.nix
    ./printing.nix
    ./options.nix
    ./hjem.nix
  ];
}
