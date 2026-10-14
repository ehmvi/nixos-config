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
    # cache binaire de kopuz, sur nixos et sur sommei. l input ne suit pas
    # notre nixpkgs : ce cache ne contient que les binaires construits avec
    # le leur. le suivre recompilerait le lecteur en local.
    substituters = [ "https://kopuz.cachix.org" ];
    trusted-public-keys = [
      "kopuz.cachix.org-1:J2X3AnAYhKTJW5S3aCLoA1ckonQXVNZMQvhZA0YAufw="
    ];
  };

  nix.gc = {
    automatic = true;
    options = lib.mkDefault "--delete-older-than 14d";
  };
}
