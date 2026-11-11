# module: desktop/hjem
# declarative dotfiles for the main user (username, symlinks via hjem)
{
  config,
  inputs,
  lib,
  pkgs,
  theme,
  username,
  ...
}:

let
  # "#rrggbb" -> "rrggbb"
  hex = c: builtins.substring 1 6 c;

  # fonds evangelion (github.com/Aleph1-9012/Evangelion), epingles sur un commit precis.
  # nix ne telecharge que ces 2 images, et verifie leur contenu grace au hash.
  lockWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Aleph1-9012/Evangelion/fb785c3009a9346173d4b893d6aa36dd22052335/wallpapers/Ayanami-wall.png";
    hash = "sha256-GdWym23O1irCSb62XTq2EU+9NnhAwE/JW9hVjeMe8M4=";
  };
  desktopWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Aleph1-9012/Evangelion/fb785c3009a9346173d4b893d6aa36dd22052335/wallpapers/Ramiel-wall.png";
    hash = "sha256-OnyTyFxrUVyGyjyG6ZEqdUvIFkDhb3lpSXChBhRrlUI=";
  };

  # wayle ne relance matugen que si le chemin du fond change, pas son contenu.
  # on lui donne donc le chemin du store : nouveau fond = nouveau chemin = nouvelles couleurs,
  # sans reconnexion (wayle relit sa config tout seul).
  # la section [styling] vient de theme.nix, commune aux deux hosts. matugen ne la remplace
  # a l'execution que si le variant est dynamique (ramiel).
  wayleConfig = pkgs.writeText "wayle-config.toml" (
    builtins.replaceStrings [ "/home/${username}/.config/hypr/wallpaper.png" ] [ "${desktopWallpaper}" ]
      (builtins.readFile config.fyrr.wayle.configFile)
    + ''

      [styling]
      theme-provider = "${if theme.dynamic then "matugen" else "wayle"}"
      rounding = "none"

      [styling.palette]
      bg = "${theme.palette.base}"
      surface = "${theme.palette.surface0}"
      elevated = "${theme.palette.surface1}"
      fg = "${theme.palette.text}"
      fg-muted = "${theme.palette.subtext0}"
      primary = "${theme.accentHex}"
      red = "${theme.palette.red}"
      yellow = "${theme.palette.yellow}"
      green = "${theme.palette.green}"
      blue = "${theme.palette.blue}"
    ''
  );

  # themes discord : depot prive ehmvi/ramiel (entree flake), un fichier par variante
  ramielThemes = builtins.mapAttrs pkgs.writeText (import "${inputs.ramiel}/themes.nix");

  # hyprlock.conf généré depuis theme.nix — plus de couleurs en dur
  hyprlockConf = pkgs.writeText "hyprlock.conf" ''
    background {
        monitor =
        path = ${lockWallpaper}
        blur_passes = 0
    }

    input-field {
        monitor =
        size = 300, 60
        position = 0, 0
        halign = center
        valign = center
        outline_thickness = 2
        rounding = 0
        dots_center = true
        fade_on_empty = false
        placeholder_text = <span foreground="##${hex theme.palette.subtext0}">Password...</span>
        font_color = rgb(${hex theme.palette.text})
        inner_color = rgb(${hex theme.palette.base})
        # bordure du champ de mot de passe : blanc
        outer_color = rgb(ffffff)
        check_color = rgb(${hex theme.palette.green})
        fail_color = rgb(${hex theme.palette.red})
        shadow_passes = 2
    }

    label {
        monitor =
        # variable interne : pas de shell lance a chaque seconde
        text = $TIME
        color = rgba(${hex theme.accentHex}, 1.0)
        font_size = 24
        font_family = JetBrainsMono Nerd Font
        position = 0, 100
        halign = center
        valign = center
    }
  '';

  # hypr-theme.lua généré depuis theme.nix — couleurs de bordure pour hyprland.lua
  hyprThemeLua = pkgs.writeText "hypr-theme.lua" ''
    -- hypr-theme.lua — variant "${theme.variant}"
    -- généré par nix depuis theme.nix, ne pas éditer à la main
    return {
        -- vrai : hyprland.lua prefere les couleurs du fond (matugen-colors.lua)
        dynamic = ${if theme.dynamic then "true" else "false"},
        active_border = "rgb(${hex theme.accentHex})",
        inactive_border = "rgb(${hex theme.palette.surface0})",
    }
  '';

  # wezterm.lua généré depuis theme.nix — plus de couleurs en dur
  weztermLua = pkgs.writeText "wezterm.lua" ''
    -- wezterm.lua — theme "${theme.variant}" (serial experiments lain)
    -- généré par nix depuis theme.nix, ne pas éditer à la main

    local wezterm = require 'wezterm'
    local config = wezterm.config_builder()

    -- police : jetbrainsmono nerd font (comme le reste de la config)
    config.font = wezterm.font_with_fallback {
      'JetBrainsMono Nerd Font',
      'Symbols Nerd Font',
    }
    config.font_size = 12.0
    config.line_height = 1.1

    -- fenetre
    config.window_background_opacity = 0.92
    config.window_decorations = 'NONE'
    config.window_padding = { left = 16, right = 16, top = 14, bottom = 12 }
    config.hide_tab_bar_if_only_one_tab = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = true
    config.default_cursor_style = 'BlinkingBar'
    config.cursor_blink_rate = 500
    -- clignotement sans fondu : wezterm ne redessine plus chaque image du fondu
    config.cursor_blink_ease_in = 'Constant'
    config.cursor_blink_ease_out = 'Constant'
    config.max_fps = 120
    config.scrollback_lines = 10000
    config.audible_bell = 'Disabled'

    -- games : en wayland natif, wezterm ne recoit pas le clavier virtuel de
    -- sunshine (stream moonlight). on passe par xwayland, seulement la.
    -- navi reste en wayland natif : en scale 1.8, xwayland rend le texte flou.
    if wezterm.hostname() == 'games' then
      config.enable_wayland = false
    end

    -- hyprland est tiling : sinon, en x11, zoomer (ctrl +/-) fait demander a
    -- wezterm un redimensionnement que hyprland refuse, et le rendu ne
    -- remplit plus la fenetre.
    config.adjust_window_size_when_changing_font_size = false

    -- couleurs : palette ${theme.variant} + les 16 ANSI
    config.colors = {
      foreground = '${theme.palette.text}',
      background = '${theme.palette.base}',
      cursor_bg = '${theme.accentHex}',
      cursor_border = '${theme.accentHex}',
      cursor_fg = '${theme.palette.crust}',
      selection_bg = '${theme.palette.surface1}',
      selection_fg = '${theme.palette.text}',
      ansi = {
        '${builtins.elemAt theme.ansi16 0}', '${builtins.elemAt theme.ansi16 1}', '${builtins.elemAt theme.ansi16 2}', '${builtins.elemAt theme.ansi16 3}',
        '${builtins.elemAt theme.ansi16 4}', '${builtins.elemAt theme.ansi16 5}', '${builtins.elemAt theme.ansi16 6}', '${builtins.elemAt theme.ansi16 7}',
      },
      brights = {
        '${builtins.elemAt theme.ansi16 8}', '${builtins.elemAt theme.ansi16 9}', '${builtins.elemAt theme.ansi16 10}', '${builtins.elemAt theme.ansi16 11}',
        '${builtins.elemAt theme.ansi16 12}', '${builtins.elemAt theme.ansi16 13}', '${builtins.elemAt theme.ansi16 14}', '${builtins.elemAt theme.ansi16 15}',
      },
    }

    return config
  '';
in
{
  hjem.users.${username} = {
    files = {
      ".config/hypr/hyprland.lua".source = ../../config/hypr/hyprland.lua;
      ".config/hypr/hypr-theme.lua".source = hyprThemeLua;
      ".config/hypr/hyprlock.conf".source = hyprlockConf;
      ".config/hypr/hypridle.conf".source = ../../config/hypr/hypridle.conf;
      ".config/hypr/wallpaper.png".source = desktopWallpaper;

      ".config/matugen/config.toml".source = ../../config/matugen/config.toml;
      ".config/matugen/templates/hypr-colors.lua".source = ../../config/matugen/hypr-colors.lua;
      ".config/matugen/templates/rofi-colors.rasi".source = ../../config/matugen/rofi-colors.rasi;
      ".config/matugen/templates/vesktop-colors.css".source =
        "${inputs.ramiel}/matugen/ramiel-colors.css";

      # theme vesktop. ramiel-colors.theme.css reste hors de hjem : matugen le reecrit
      ".config/vesktop/themes/ramiel.theme.css".source = ramielThemes."ramiel.theme.css";

      # theme equibop : ramiel en orange fige pour distinguer les deux clients
      # (pas de matugen ici, voulu). clobber : remplace une copie posee a la main
      ".config/equibop/themes/ramiel-orange.theme.css" = {
        source = ramielThemes."ramiel-orange.theme.css";
        clobber = true;
      };

      ".config/wezterm/wezterm.lua".source = weztermLua;

      # .text = theme.render : le fichier natif avec ses @cle@ remplis par theme.nix
      ".config/fastfetch/config.jsonc".text = theme.render ../../config/fastfetch/config.jsonc;

      ".config/nushell/config.nu".source = ../../config/nushell/config.nu;
      ".config/nushell/env.nu".source = ../../config/nushell/env.nu;

      ".config/starship.toml".text = theme.render ../../config/starship/starship.toml;

      # theme zed "theme.nix". settings.json reste a zed (il le reecrit) : le theme
      # se choisit une fois dans zed (theme selector: toggle)
      ".config/zed/themes/theme-nix.json".text = theme.render ../../config/zed/theme.json;

      ".config/wayle/tombi.toml".source = ../../config/wayle/tombi.toml;
      ".config/wayle/config.toml".source = wayleConfig;
      ".config/wayle/schema.json".source = ../../config/wayle/schema.json;

      ".config/git/config".source = ../../config/git/config;

      # rofi : palette de theme.nix, puis celle du fond par-dessus si le variant est dynamique
      ".config/rofi/config.rasi".text =
        theme.render ../../config/rofi/config.rasi
        + lib.optionalString theme.dynamic ''

          /* couleurs du fond d ecran (generees par matugen), par-dessus celles de theme.nix */
          @import "~/.config/rofi/matugen-colors.rasi"
        '';
    };
  };
}
