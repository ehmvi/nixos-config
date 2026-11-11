# theme.nix : colonne vertébrale colorimétrique, sélection par variant.
#
# `variant` est le SEUL knob qui retourne toute la machine :
#   "ramiel"  -> vert-noir + sarcelle, la palette du fond ramiel (defaut)
#   "blood"   -> near-black + plum-rose sourd
#   "copland" -> ambre chaud, tube CRT copland-os (serial experiments lain)
#
# `mauve` est le SLOT accent — or en copland, plum-rose en blood — pas une couleur fixe.
# les palettes partagent les mêmes 26 clés sémantiques (convention catppuccin) par contrat,
# donc tout consommateur qui interpole `theme.palette.<clé>` se rethème automatiquement.
#
# deux couches, pas plus :
#   - theme.nix (a la construction) : tout ce qui est statique. les fichiers natifs de
#     config/ portent des marqueurs @cle@ que `render` remplace (voir en bas).
#   - matugen (a l'execution, lance par wayle sur le fond d ecran) : bordures hyprland,
#     rofi, vesktop et la barre wayle. seulement si `dynamic` est vrai : ramiel est
#     justement la sortie de matugen sur le fond epingle, les deux couches donnent donc
#     les memes couleurs tant que le fond ne change pas.
#
# importé une fois dans flake.nix et threadé partout comme specialArg `theme`.
let
  variant = "ramiel"; # "ramiel" | "blood" | "copland"

  # variants qui suivent le fond d ecran a l'execution (matugen). les autres restent
  # figes : wayle garde sa palette statique, hyprland et rofi ignorent les fichiers matugen.
  dynamic = variant == "ramiel";

  palettes = {
    # ramiel : la palette des themes ramiel (vesktop, obsidian, kopuz), soit la sortie de
    # matugen (schema sombre, tonal-spot) sur Ramiel-wall.png, plus deux couleurs hors
    # matugen. surfaces vert-noir, accent sarcelle, texte sourd au repos.
    # red = le rouge-orange du core, seule couleur chaude du fond : a garder rare
    # (erreurs, danger, mentions, dnd). yellow = ambre (idle, avertissements).
    # pas de violet dans le fond : lavender est le secondary matugen (gris-vert).
    ramiel = {
      rosewater = "#cde8e0"; # secondary fixe, pale
      flamingo = "#ffdad6"; # on_error_container
      pink = "#ee7a5a"; # core eclairci
      mauve = "#85d6c1"; # ACCENT : primary, sarcelle
      red = "#e8502a"; # core : rare, erreurs / danger uniquement
      maroon = "#ffb4ab"; # error matugen, rouge doux
      peach = "#e18952"; # core et ambre a parts egales
      yellow = "#d9c27a"; # ambre, avertissements / idle
      green = "#85d6c1"; # primary : pas d'autre vert dans le fond, succes = accent
      teal = "#a0f2dd"; # primary fixe (on_primary_container)
      sky = "#cbe6ff"; # tertiary fixe
      sapphire = "#819aad"; # tertiary assombri
      blue = "#aacbe4"; # tertiary, structure / dossiers / liens externes
      lavender = "#b1ccc4"; # secondary
      text = "#dee4e0"; # on_surface, texte vif (survol, titres)
      subtext1 = "#bfc9c4"; # on_surface_variant, texte courant
      subtext0 = "#89938f"; # outline, icones et texte sourd
      overlay2 = "#737d79";
      overlay1 = "#5d6763"; # commentaires, heures (text-5 de vesktop)
      overlay0 = "#3f4946"; # outline_variant, bordure de panneau actif
      surface2 = "#303634"; # surface_container_highest
      surface1 = "#252b29"; # surface_container_high, selection
      surface0 = "#1b211f"; # surface_container, bordure au repos
      base = "#0e1513"; # surface, fond
      mantle = "#090f0e"; # surface_container_lowest
      crust = "#050908";
    };

    # copland amber : le tube tachibana labs / copland os. ambre chaud sur noir chaud,
    # un CRT phosphore-P1 analogique. la luminosité porte la hiérarchie, pas la teinte ;
    # rust-red est le seul contraste (erreurs), jaune-vert chaud = « la machine a répondu ».
    copland = {
      rosewater = "#e8d2a8";
      flamingo = "#e0b890";
      pink = "#e0a890";
      mauve = "#ffc24d"; # ACCENT : or vif
      red = "#d9442f"; # rust-red, erreurs / seul contraste
      maroon = "#e85a3a";
      peach = "#e89a4a"; # orange chaud
      yellow = "#f0c860"; # ambre-jaune, avertissements
      green = "#b9c46a"; # jaune-vert chaud, succès
      teal = "#9ab884";
      sky = "#d6bd72";
      sapphire = "#c8a850";
      blue = "#c89a58"; # tan chaud, pas de bleu dans le monde ambre
      lavender = "#d8bd84";
      text = "#d8b25a"; # ambre fg
      subtext1 = "#c4a050";
      subtext0 = "#8a6e34"; # dim
      overlay2 = "#705a28";
      overlay1 = "#5c4a22"; # commentaires
      overlay0 = "#4a3c1c";
      surface2 = "#382e18";
      surface1 = "#28200f"; # sélection / bordure inactive
      surface0 = "#1a1610"; # surface
      base = "#0b0a07"; # bg, noir chaud
      mantle = "#080704";
      crust = "#050402";
    };

    # blood & static (défaut) : near-black avec un accent plum/wine sourd,
    # texte gris-violet doux. atténué depuis le crimson pour rester moody et lain,
    # pas alarmant ; l'accent reste lisible sur la barre sombre.
    # red est réservé aux vraies erreurs.
    blood = {
      rosewater = "#d8ccd4";
      flamingo = "#c8aab8";
      pink = "#c79ab4";
      mauve = "#bf7593"; # ACCENT : plum-rose sourd, prompt/liens/actif
      red = "#c0667e"; # rose-red sourd, erreurs uniquement
      maroon = "#d07e96";
      peach = "#b07e90"; # mauve-pêche sourd
      yellow = "#c4a878"; # ambre sourd, avertissements
      green = "#82a08c"; # sauge sourd, succès
      teal = "#6f9a98";
      sky = "#8c8aa6";
      sapphire = "#9a72a0";
      blue = "#8a7aa6"; # violet-bleu sourd, mots-clés / dossiers / structure
      lavender = "#b09cc0";
      text = "#c2b6c0"; # gris-violet doux fg
      subtext1 = "#a89ca6";
      subtext0 = "#948a98"; # dim mais lisible
      overlay2 = "#6e6470";
      overlay1 = "#4c4450"; # commentaires
      overlay0 = "#3c3442";
      surface2 = "#2a2430";
      surface1 = "#1e1824"; # sélection / bordure inactive
      surface0 = "#151019"; # surface
      base = "#0d0a0e"; # bg, near-black, pointe de violet
      mantle = "#0a070b";
      crust = "#060406";
    };
  };

  # les 16 couleurs ANSI par variant (index 0..15 : black, red, green, yellow, blue,
  # magenta, cyan, white, puis les 8 bright).
  terminal16 = {
    # ramiel : peu de teintes, comme le fond. cyan = melange primary / tertiary,
    # magenta = secondary (pas de violet). le rouge est le core.
    ramiel = [
      "#252b29"
      "#e8502a"
      "#85d6c1"
      "#d9c27a"
      "#aacbe4"
      "#b1ccc4"
      "#97d1d3"
      "#bfc9c4"
      "#5d6763"
      "#ee7a5a"
      "#a0f2dd"
      "#e0cd92"
      "#cbe6ff"
      "#cde8e0"
      "#b5e6ea"
      "#dee4e0"
    ];
    copland = [
      "#28200f"
      "#d9442f"
      "#b9c46a"
      "#f0c860"
      "#c89a58"
      "#e0a06a"
      "#d8b25a"
      "#e8c88a"
      "#5c4a22"
      "#e85a3a"
      "#cdd47a"
      "#ffd870"
      "#e0b070"
      "#f0b888"
      "#ecc888"
      "#f7ecca"
    ];
    blood = [
      "#1e1824"
      "#c0667e"
      "#82a08c"
      "#c4a878"
      "#8a7aa6"
      "#bf7593"
      "#6f9a98"
      "#c2b6c0"
      "#4c4450"
      "#d07e96"
      "#9ab4a2"
      "#d4bc90"
      "#a08cc0"
      "#cf90ac"
      "#8ab4b0"
      "#e0d6dc"
    ];
  };

  accent = "mauve"; # le SLOT accent (or en copland, plum-rose en blood)
  palette = palettes.${variant};
  ansi16 = terminal16.${variant};

  # "#rrggbb" -> "r,g,b" (format des couleurs kde)
  hexDigits = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };
  byte =
    c: i: hexDigits.${builtins.substring i 1 c} * 16 + hexDigits.${builtins.substring (i + 1) 1 c};
  rgb = c: "${toString (byte c 1)},${toString (byte c 3)},${toString (byte c 5)}";

  # couleurs nommees pour `render` : les 26 cles, `accent`, et ansi0 .. ansi15
  named =
    palette
    // {
      accent = palette.${accent};
    }
    // builtins.listToAttrs (
      builtins.genList (i: {
        name = "ansi${toString i}";
        value = builtins.elemAt ansi16 i;
      }) 16
    );
  names = builtins.attrNames named;
in
{
  inherit
    variant
    dynamic
    accent
    palette
    ansi16

    ;
  accentHex = palette.${accent};

  # lit un fichier natif et remplace ses marqueurs par la palette du variant :
  #   @cle@     -> "#rrggbb"   (ex. @base@, @accent@, @ansi4@)
  #   @cle.hex@ -> "rrggbb"    (sans diese, ex. hyprland ou spicetify)
  #   @cle.rgb@ -> "r,g,b"     (kde)
  #   @variant@ -> nom du variant
  # le fichier reste lisible tel quel dans config/, nix ne fait que remplir les trous.
  render =
    path:
    builtins.replaceStrings
      (
        map (n: "@${n}@") names
        ++ map (n: "@${n}.hex@") names
        ++ map (n: "@${n}.rgb@") names
        ++ [ "@variant@" ]
      )
      (
        map (n: named.${n}) names
        ++ map (n: builtins.substring 1 6 named.${n}) names
        ++ map (n: rgb named.${n}) names
        ++ [ variant ]
      )
      (builtins.readFile path);
}
