# module: programs/cli
# terminal tools — tmux, just, gh
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    just
    gh
  ];
}
