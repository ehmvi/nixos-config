# module: desktop/audio
# pipewire + rtkit (pulseaudio disabled)
{
  pkgs,
  inputs,
  username,
  ...
}:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # nixos pose deja les limites pam (rtprio 95, memlock 4 go) pour @pipewire :
  # sans ce groupe, bitwig et fsa restent en priorite normale.
  users.users.${username}.extraGroups = [ "pipewire" ];

  # fsa: mic processor, creates its own "Mic (processed)" pipewire source from the user session.
  # package only, no module needed on linux (sommei gets it through the darwin module)
  environment.systemPackages = [
    inputs.fsa.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
