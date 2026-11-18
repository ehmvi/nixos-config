# module: programs/craft
# suite craft d'artcraft, sur les 3 hosts (nixos et darwin). une entree de
# pkgs/craft-apps.json par app : depot github, version, hash du tarball linux
# et hash du dmg mac. `just bump-craft` (lance par `just update`) les avance.
# solidcraft est une app communautaire (tangency-labs), les autres sont
# officielles (storytold).
{ pkgs, lib, ... }:

let
  sources = lib.importJSON ../../pkgs/craft-apps.json;
  darwin = pkgs.stdenv.hostPlatform.isDarwin;
  builder = if darwin then ../../pkgs/craft-app-darwin.nix else ../../pkgs/craft-app.nix;
in
{
  environment.systemPackages = lib.mapAttrsToList (
    pname: src:
    pkgs.callPackage builder {
      inherit pname;
      inherit (src) repo version;
      hash = if darwin then src.darwin else src.linux;
    }
  ) sources;
}
