# mistral vibe de nixpkgs, avec trois retouches :
# - vibe-rs (la tui rust) : le hook cargo de nixpkgs exporte
#   AWS_LC_SYS_USE_SYSTEM=1 pour tout paquet rust. aws-lc-sys cherche alors un
#   aws-lc systeme, que vibe-rs ne declare pas, et la 3.1.0 ne compile plus. on
#   le lui donne, comme monocle ou arnis.
# - tests python : 14 min, et 4 sur 10 800 echouent par course de timing quand la
#   machine est chargee ("A turn is already running"). on les saute.
# - mise a jour : vibe se met a jour lui-meme avec uv, impossible dans le store.
#   on coupe la verification et la mise a jour auto (couche VIBE_* de sa config,
#   --set-default : un export du shell gagne), et `vibe update` renvoie vers le
#   flake. la version suit flake.lock : `just update` puis `just switch`.
# les deux premieres sont a retirer quand nixpkgs aura repare le paquet.
{ mistral-vibe, aws-lc }:

mistral-vibe.overrideAttrs (old: {
  doInstallCheck = false;

  # apres wrapPythonPrograms, qui ouvre postFixup
  postFixup = (old.postFixup or "") + ''
    for bin in vibe vibe-acp vibe-app-server; do
      wrapProgram $out/bin/$bin \
        --set-default VIBE_ENABLE_UPDATE_CHECKS false \
        --set-default VIBE_ENABLE_AUTO_UPDATE false
    done
    wrapProgram $out/bin/vibe \
      --run 'case "''${1-}" in update | --check-upgrade) echo "✗ Vibe comes from Nix: update it with \`just update\` then \`just switch\` in nixos-config" >&2; exit 1 ;; esac'
  '';

  passthru = old.passthru // {
    vibe-rs = old.passthru.vibe-rs.overrideAttrs (o: {
      buildInputs = o.buildInputs ++ [ aws-lc ];
    });
  };
})
