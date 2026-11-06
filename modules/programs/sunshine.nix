# module: programs/sunshine
# serveur sunshine (games) : service, script de mode ecran, ports tailscale0
{
  config,
  pkgs,
  lib,
  ...
}:
let
  sunshineMonitor = pkgs.callPackage ../../pkgs/sunshine-monitor.nix {
    hyprland = config.programs.hyprland.package;
    systemd = config.systemd.package;
  };
in
{
  # stream du bureau vers le mac (moonlight), seulement via tailscale.
  # openFirewall reste faux : le module ouvrirait aussi le tcp 47990 et
  # l'udp 48002 et 48010, sur toutes les interfaces.
  # le paquet par defaut est celui du cache, construit sans cuda :
  # cudaSupport suit nixpkgs.config.cudaSupport, faux ici. ffmpeg
  # embarque essaie quand meme h264_nvenc. le journal dit qui a gagne.
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = false;
    # capture kms (drm), pas propre a nvidia. sous hyprland, sunshine
    # passe par wlroots et s'en passe. true donnerait cap_sys_admin,
    # presque root, a un binaire que n'importe quel utilisateur lance.
    capSysAdmin = false;
    # pc : l'ui web ne repond qu'a localhost. fermer le port 47990 dans
    # nixos ne suffit pas, ts-input accepte tout tailscale0. 100.64/10
    # est un lan pour sunshine, et son defaut accepte le lan.
    # ce reglage ecrit sunshine.conf dans le store, en lecture seule :
    # l'ui ne peut plus y sauver ses options. le mot de passe, les
    # certificats et les clients apparies vont ailleurs
    # (~/.config/sunshine/sunshine_state.json et credentials/).
    # global_prep_cmd : chaine json, le module n'accepte pas une liste.
    settings = {
      origin_web_ui_allowed = "pc";
      # sans capture fixee, sunshine essaie aussi le portail xdg au
      # demarrage. xdph ouvre alors "select what to share" et sunshine
      # attend un clic avant d'ecouter. en stream a distance, personne ne
      # clique : apres le redemarrage de fin de session, moonlight ne
      # pouvait plus se connecter. wlr capture tout l'ecran sans demander.
      capture = "wlr";
      # l'undo ne tourne qu'a la fin de la session moonlight, pas sur une
      # deconnexion. "quit app on host pc after ending stream" doit rester
      # cochee, sinon le mode 1440p ne revient pas, sunshine ne redemarre
      # pas et la vram s'accumule.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${sunshineMonitor} apply";
          undo = "${sunshineMonitor} restore";
        }
      ];
    };
  };

  # ffmpeg fait dlopen("libcuda.so.1") et dlopen("libnvidia-encode.so.1").
  # ces fichiers sont dans /run/opengl-driver/lib (hardware.nvidia les y
  # met deja). un service utilisateur n'herite pas le LD_LIBRARY_PATH de
  # la session, donc le chargement echoue. le chargeur renvoie -1, et
  # ffmpeg ecrit cela "Operation not permitted" : ce n'est pas le bac a
  # sable, ni /dev/nvidia*. cap_sys_admin reste faux, la capture hyprland
  # passe par wlroots. sans le cuda compile dans sunshine, l'image copie
  # gpu, ram, gpu, et l'encodage reste nvenc. cudaSupport = true
  # recompilerait le paquet avec nvcc (toolkit cuda, unfree, souvent
  # hors du cache) seulement pour eviter cette copie.
  # ne marche plus si capSysAdmin = true : le wrapper efface LD_LIBRARY_PATH.
  systemd.user.services.sunshine.environment.LD_LIBRARY_PATH =
    "${pkgs.addDriverRunpath.driverLink}/lib";

  # le module limite sunshine a 5 demarrages en 500 s. chaque fin de
  # session moonlight le redemarre : des reconnexions rapprochees ont
  # atteint la limite (start-limit-hit), le service est reste arrete, et
  # un sunshine lance a la main a garde la vram de 5 sessions. 0 coupe la
  # limite. relancer avec systemctl --user restart sunshine, jamais le
  # binaire seul : hors du service, rien ne le redemarre apres un stream.
  systemd.user.services.sunshine.startLimitIntervalSec = lib.mkForce 0;

  # le module sunshine allume avahi (mkDefault) pour le reseau local.
  # le mac et le telephone joignent games par le nom ou l'ip tailscale.
  # cups est installe, mais il ne demande pas avahi : seul cups-browsed
  # s'en sert, pour trouver les imprimantes du lan. on le coupe avec.
  # sans le demon, sunshine ecrit "Failed to create client" et continue.
  services.avahi.enable = false;

  # ts-input accepte tout tailscale0 avant nixos-fw, donc cette liste ne
  # filtre pas aujourd'hui. on la garde : si cet accept disparait, seuls
  # ces ports passent, et seulement sur tailscale0. pas le 47990.
  # le vrai filtre, shields-up etant coupe, ce sont les acls tailscale.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      47984
      47989
      48010
    ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48000;
      }
    ];
  };
}
