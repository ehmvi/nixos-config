# module: desktop/fonts
# system fonts — jetbrains mono nerd font
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    # emoji en couleur, deja tire par les paquets par defaut de nixos : on le dit ici
    noto-fonts-color-emoji
    # police proportionnelle, pour les pages et les documents qui demandent sans-serif
    inter
  ];

  # polices par defaut de fontconfig. l'interface reste en jetbrains mono (gtk, qt,
  # vesktop, obsidian) ; sans-serif ne sert qu'au contenu. serif garde dejavu.
  # les emoji passent apres chaque famille, en couleur.
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono Nerd Font"
      "Noto Sans Mono CJK JP"
    ];
    sansSerif = [
      "Inter"
      "Noto Sans CJK JP"
    ];
    emoji = [ "Noto Color Emoji" ];
  };
}
