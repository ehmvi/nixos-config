# host: games
# desktop pc — gaming/multimedia
{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/health.nix
    ../../modules/hardware/nvidia-power.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/programs/cli.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/office.nix
    ../../modules/programs/apps.nix
    ../../modules/programs/spicetify.nix
  ];

  networking.hostName = "games";
  console.keyMap = "fr";
  # dual boot : la rtc reste en utc. côté windows, clé registre RealTimeIsUniversal = 1
  services.xserver.xkb.layout = "fr";
  # git-lfs pour le depot de fichiers .blend, seulement sur games
  programs.git.lfs.enable = true;
  fyrr.wayle.configFile = ../../config/wayle/config-games.toml;

  boot.kernelModules = [ "nct6775" ];

  programs.coolercontrol.enable = true;

  # glm-4.7-flash en local. ollama 0.40.2 gere glm4moelite
  # (llama.cpp b11351). le paquet cuda manque dans cache.nixos.org et
  # compilerait llama.cpp avec nvcc. vulkan est deja en cache et passe
  # par le pilote nvidia deja installe. ecoute seulement sur localhost.
  # le quant q4_k_m (~19 go) se telecharge a la main, hors du store.
  # la rtx 4070 a 12 go : le surplus part en ram.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    openFirewall = false;
  };

  # stream du bureau vers le mac (moonlight), seulement via tailscale.
  # openFirewall reste faux : il ouvrirait ces ports sur toutes les interfaces.
  # ports du module (base 47989), sans le tcp 47990 : l'interface web
  # reste sur localhost pour saisir le pin.
  # le paquet par defaut est sans cuda et vient du cache. nvenc passe par le pilote nvidia.
  services.sunshine = {
    enable = true;
    autoStart = true;
    # cap_sys_admin, presque root. requis pour la capture kms avec nvidia.
    capSysAdmin = true;
  };

  # le module allume avahi pour la decouverte sur le reseau local.
  # le mac joint games par son nom tailscale, donc on n'ouvre pas le port 5353.
  services.avahi.openFirewall = false;

  # ts-input accepte tout tailscale0 avant le pare-feu nixos (iptables,
  # nftables desactive). cette liste ne filtre donc pas aujourd'hui.
  # le vrai controle est shields-up, ou les acls tailscale.
  # on la garde pour l'intention, et si ts-input est un jour coupe.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      47984
      47989
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
      48002
      48010
    ];
  };

  system.stateVersion = "25.11";
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/egctl.nix { })
    # blender sans cuda : cudaSupport = true compile depuis les sources, sans cache binaire
    pkgs.blender
    # release linux officielle : le paquet nixpkgs exige la rom us a la compilation
    (pkgs.callPackage ../../pkgs/sm64coopdx.nix { })
    # decoupe video sans reencodage. nixpkgs suit la derniere release upstream.
    # le paquet source est dans le cache. losslesscut-bin reconstruirait un wrapper fhs en local.
    pkgs.losslesscut
  ];
}
