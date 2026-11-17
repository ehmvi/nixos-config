# module: programs/cli
# terminal tools — tmux, just, gh, direnv, zoxide, carapace
{ lib, pkgs, ... }:

let
  # init nushell genere au build en autoload vendor : rien ne se relance a chaque shell.
  # nom en -init : zoxide fournit deja zoxide.nu (ses completions) au meme endroit
  nuAutoload =
    name: cmd:
    pkgs.runCommand "${name}-nushell-autoload" { } ''
      export HOME=$TMPDIR
      mkdir -p $out/share/nushell/vendor/autoload
      ${cmd} > $out/share/nushell/vendor/autoload/${name}-init.nu
    '';
in
{
  environment.systemPackages = with pkgs; [
    tmux
    just
    gh
    zoxide
    carapace
  ];

  # direnv + nix-direnv (actif par defaut) : un .envrc `use flake` charge le devshell
  # en entrant dans le dossier, et nix-direnv garde une racine gc pour que le gc
  # hebdomadaire ne le supprime pas. hook nushell via programs.nushell (core/users)
  programs.direnv.enable = true;

  programs.nushell.autoloads = [
    # z <motif> saute vers un dossier deja visite (zi demanderait fzf, absent)
    (nuAutoload "zoxide" "${lib.getExe pkgs.zoxide} init nushell")
    # completions de centaines de commandes externes (git, nix, systemctl...).
    # la ligne qui ajoute ~/.config/carapace/bin au PATH est retiree : au build,
    # elle pointerait vers le HOME du sandbox, et les specs perso ne servent pas ici
    (nuAutoload "carapace" "${lib.getExe pkgs.carapace} _carapace nushell | grep -v carapace/bin")
  ];
}
