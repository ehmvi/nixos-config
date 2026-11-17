# module: core/users
# utilisateur principal (username, via specialArgs) + nushell
{ pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.nushell;
  };

  # nushell dans /etc/shells (liste des shells de connexion autorises)
  environment.shells = [ pkgs.nushell ];

  # le module nixos plutot que des hooks colles dans config.nu : les integrations
  # (direnv, autoloads de programs/cli) arrivent en autoload vendor, dans
  # /run/current-system/sw/share/nushell/vendor/autoload, et suivent leurs paquets.
  # il installe le meme pkgs.nushell que le shell de connexion
  programs.nushell.enable = true;

}
