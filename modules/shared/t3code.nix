# module: shared/t3code
# telemetrie de t3 code coupee, sur les 3 hosts (stable, nightly, cask).
# mkHost importe ce module.
{ lib, options, ... }:

let
  vars = {
    T3CODE_TELEMETRY_ENABLED = "false";
    T3CODE_OTEL_SDK_DISABLED = "true";
  };
  # passerelle d'ingestion fermee : bloquee dans /etc/hosts, en plus des variables.
  ingest = "ingest.t3.codes";
in
{
  # optionalAttrs, pas mkIf : meme raison que shared/sops.
  config = lib.mkMerge [
    # nixos : sessionVariables, posees par PAM pour toute la session (hyprland compris).
    (lib.optionalAttrs (options.environment ? sessionVariables) {
      environment.sessionVariables = vars;
    })
    # darwin : environment.variables pour les shells, launchd pour le cask
    # lance depuis le finder ou le dock, qui ne voit pas l env de fish.
    (lib.optionalAttrs (!(options.environment ? sessionVariables)) {
      environment.variables = vars;
      launchd.user.envVariables = vars;
    })
    # nixos : networking.hosts ecrit /etc/hosts.
    (lib.optionalAttrs (options.networking ? hosts) {
      networking.hosts = {
        "127.0.0.1" = [ ingest ];
        "::1" = [ ingest ];
      };
    })
    # darwin : pas d'option hosts, /etc/hosts est un vrai fichier. on ajoute
    # les lignes une seule fois (reperees par le commentaire), puis on vide
    # le cache dns. mkAfter : s'ajoute au postActivation de sommei.
    (lib.optionalAttrs (!(options.networking ? hosts)) {
      system.activationScripts.postActivation.text = lib.mkAfter ''
        if ! grep -qF '# t3code-telemetry' /etc/hosts; then
          echo "blocking ${ingest} in /etc/hosts..." >&2
          if [ -s /etc/hosts ] && [ -n "$(tail -c 1 /etc/hosts)" ]; then
            printf '\n' >> /etc/hosts
          fi
          printf '127.0.0.1 ${ingest} # t3code-telemetry\n::1 ${ingest} # t3code-telemetry\n' >> /etc/hosts
          dscacheutil -flushcache || true
          killall -HUP mDNSResponder 2>/dev/null || true
        fi
      '';
    })
  ];
}
