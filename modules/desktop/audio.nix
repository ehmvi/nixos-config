# module: desktop/audio
# pipewire + rtkit (pulseaudio disabled)
{ pkgs, inputs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # fsa: mic processor, creates its own "Mic (processed)" pipewire source from the user session.
  # package only, no module needed on linux (sommei gets it through the darwin module)
  environment.systemPackages = [
    inputs.fsa.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
