# module: desktop
# groups shared graphical modules
{ ... }:

{
  imports = [
    ./hyprland.nix
    ./sddm.nix
    ./audio.nix
    ./fonts.nix
    ./cursor.nix
    ./printing.nix
    ./hjem.nix
  ];
}
