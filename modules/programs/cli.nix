# module: programs/cli
# terminal tools — tmux, just, gh, direnv
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    just
    gh
  ];

  # direnv + nix-direnv (actif par defaut) : un .envrc `use flake` charge le devshell
  # en entrant dans le dossier, et nix-direnv garde une racine gc pour que le gc
  # hebdomadaire ne le supprime pas. hook nushell via programs.nushell (core/users)
  programs.direnv.enable = true;
}
