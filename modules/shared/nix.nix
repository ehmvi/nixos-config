# module: shared/nix
# reglages nix communs a nixos et nix-darwin.
# dates et persistent restent dans modules/core/system.nix : ce sont des
# options systemd, retirees par nix-darwin (mkRemovedOptionModule).
{ lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nix.gc = {
    automatic = true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
