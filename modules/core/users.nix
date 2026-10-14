# module: core/users
# utilisateur principal (username, via specialArgs) + nushell
{ pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = "paul";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.nushell;
  };

  # nushell dans /etc/shells (liste des shells de connexion autorises)
  environment.shells = [ pkgs.nushell ];

}
