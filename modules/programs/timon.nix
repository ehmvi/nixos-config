# module: programs/timon
# timon (pkgs/timon.nix) sur navi et games. sommei prend pkgs/timon-darwin.nix.
#
# l'app installe elle-meme son daemon : un service systemd --user
# (timon-desktop-<id>), lance depuis une copie du paquet dans
# ~/.timon/desktop-runtime/releases/<version>. cette copie charge ses
# bibliotheques dans le store (node, modules natifs), mais le gc ne la voit pas.
# et la copie n'est refaite qu'au changement de version de timon : apres une
# mise a jour de nixpkgs, elle pointe vers l'ancien paquet, que le gc
# hebdomadaire finirait par effacer.
# d'ou timon-gcroot : il lit dans release-source.json le paquet copie et le
# garde en racine gc, a l'ouverture de session et a chaque nouvelle copie.
{ config, pkgs, ... }:

let
  runtime = "%h/.timon/desktop-runtime";
in
{
  environment.systemPackages = [ (pkgs.callPackage ../../pkgs/timon.nix { }) ];

  systemd.user.services.timon-gcroot = {
    description = "Keep the store package of Timon's runtime copy alive";
    wantedBy = [ "default.target" ];
    path = [
      config.nix.package
      pkgs.jq
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      runtime="$HOME/.timon/desktop-runtime"
      [ -f "$runtime/release-source.json" ] || exit 0
      root=$(jq -r '.root // empty' "$runtime/release-source.json")
      case "$root" in
        /nix/store/*) ;;
        *) exit 0 ;;
      esac
      pkg=$(printf '%s\n' "$root" | cut -d/ -f1-4)
      if [ ! -e "$pkg" ]; then
        echo "$pkg a deja ete efface : ouvrir timon-desktop pour refaire la copie" >&2
        exit 1
      fi
      nix-store --add-root "$runtime/nix-gcroot" --realise "$pkg" >/dev/null
    '';
  };

  systemd.user.paths.timon-gcroot = {
    wantedBy = [ "default.target" ];
    pathConfig.PathChanged = [
      "${runtime}/release-source.json"
      "${runtime}/active-release"
    ];
  };
}
