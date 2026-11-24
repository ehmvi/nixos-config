# module: shared/t3code
# telemetrie de t3 code coupee, sur les 3 hosts (stable, nightly, cask).
# mkHost importe ce module.
{ lib, options, ... }:

let
  vars = {
    T3CODE_TELEMETRY_ENABLED = "false";
    T3CODE_OTEL_SDK_DISABLED = "true";
  };
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
  ];
}
