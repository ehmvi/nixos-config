# module: core/system
# boot, locale, nix daemon, zram, shared cli packages
{ lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  # 10 générations max dans le menu de boot : évite de remplir l esp (/boot)
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # mkDefault : valeurs partagees, un host peut les surcharger sans mkForce
  time.timeZone = lib.mkDefault "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  # mkDefault par cle : un host qui surcharge une seule variable lc_ garde les autres
  i18n.extraLocaleSettings = lib.mapAttrs (_: lib.mkDefault) {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # dates/persistent : options systemd, retirees sur nix-darwin.
  # automatic et options sont dans modules/shared/nix.nix.
  nix.gc = {
    dates = "weekly";
    persistent = true;
  };

  # auto-optimise-store est volontairement nixos-only : sur darwin l option
  # peut corrompre le store, sommei utilise nix.optimise.automatic a la place.
  # le cache kopuz est dans modules/shared/nix.nix (nixos et darwin).
  nix.settings.auto-optimise-store = true;

  # swap compressé en ram (zram) : filet de sécurité quand la ram est pleine, zéro écriture disque
  zramSwap.enable = true;

  # mounts removable drives (usb sticks); not enabled outside plasma, so i enable it explicitly
  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    fastfetch
    git
    unzip
    claude-code
    # paquet seul et pas programs.starship : le module nixos n initialise que
    # bash/zsh/fish/xonsh, pas nushell. l init nu est faite dans config/nushell/
    starship
  ];
}
