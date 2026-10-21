# leds du host games. openrgb les eteint une fois au demarrage, puis quitte.
# pas de module nixos : il installerait des regles udev (i2c et /dev/port
# pour l'utilisateur connecte) et un serveur sdk. ici seul root y touche,
# le temps du script. carte asus tuf h770-pro, i7-13700kf : bus smbus intel.
{
  pkgs,
  lib,
  ...
}:
{
  boot.kernelModules = [
    "i2c-dev"
    "i2c-i801"
  ];

  systemd.services.openrgb-leds-off = {
    description = "Turn off RGB LEDs that OpenRGB can control";
    wantedBy = [ "multi-user.target" ];
    # pas d'after sur dev-usb.device : /dev/usb est un repertoire, l'unite
    # peut ne jamais apparaitre et le boot attendrait 90 s. udev doit
    # juste avoir cree les noeuds avant qu'openrgb les ouvre.
    after = [
      "systemd-modules-load.service"
      "systemd-udevd.service"
    ];
    environment.QT_QPA_PLATFORM = "offscreen";
    serviceConfig = {
      # type=exec : multi-user est debloque des l'exec du script, pas a la
      # fin de la detection (~15 s avec oneshot). remainafterexit laisse
      # l'unite active (exited) apres un succes, et failed si le code n'est
      # pas zero.
      Type = "exec";
      RemainAfterExit = true;
      # la config et les logs restent ici, pas dans /root
      StateDirectory = "openrgb-leds-off";
      WorkingDirectory = "/var/lib/openrgb-leds-off";
      # pas de reseau : le processus ne peut pas ouvrir le port 6742
      PrivateNetwork = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      NoNewPrivileges = true;
      # PrivateDevices remplacerait /dev par un tmpfs presque vide, et
      # DevicePolicy=closed fermerait le reste. ProtectKernelTunables
      # figerait /sys en lecture seule. on ne les active pas : root doit
      # pouvoir ouvrir /dev/i2c-*, /dev/port et les hidraw.
      PrivateDevices = false;
      DevicePolicy = "auto";
      ExecStart = pkgs.writeShellScript "openrgb-leds-off" ''
        # un --mode off global est dangereux. si l'appareil n'a pas ce
        # mode, openrgb active le mode 0, souvent un effet qui reste
        # allume. on lit les modes de chaque appareil et on choisit.
        set -euo pipefail

        openrgb=${lib.getExe pkgs.openrgb}

        mode_present() {
          local want="''${1,,}" rest="$2" tok
          rest="''${rest//\[/}"
          rest="''${rest//\]/}"
          while [[ -n "$rest" ]]; do
            rest="''${rest#"''${rest%%[![:space:]]*}"}"
            [[ -z "$rest" ]] && break
            if [[ "$rest" == \'* ]]; then
              rest="''${rest:1}"
              tok="''${rest%%\'*}"
              rest="''${rest#*\'}"
            else
              tok="''${rest%%[[:space:]]*}"
              rest="''${rest#"$tok"}"
            fi
            if [[ "''${tok,,}" == "$want" ]]; then
              return 0
            fi
          done
          return 1
        }

        args=()
        id=""
        modes=""

        flush() {
          [[ -z "$id" ]] && return 0
          if mode_present off "$modes"; then
            echo "appareil ''${id} : mode off"
            args+=(--device "$id" --mode off)
          elif mode_present static "$modes"; then
            echo "appareil ''${id} : static 000000"
            args+=(--device "$id" --mode static --color 000000)
          else
            echo "appareil ''${id} : couleur 000000, pas de mode off ni static"
            args+=(--device "$id" --color 000000)
          fi
        }

        list="$("$openrgb" --noautoconnect --localconfig --list-detailed)"

        while IFS= read -r line; do
          if [[ "$line" =~ ^([0-9]+): ]]; then
            flush
            id="''${BASH_REMATCH[1]}"
            modes=""
          elif [[ "$line" =~ ^[[:space:]]*Modes:[[:space:]]*(.*)$ ]]; then
            modes="''${BASH_REMATCH[1]}"
          fi
        done <<< "$list"
        flush

        if (( ''${#args[@]} == 0 )); then
          echo "aucun appareil openrgb"
          exit 0
        fi

        exec "$openrgb" --noautoconnect --localconfig "''${args[@]}"
      '';
    };
  };
}
