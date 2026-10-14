# module: desktop/hjem
# declarative dotfiles for the main user (username, symlinks via hjem)
{
  config,
  lib,
  pkgs,
  theme,
  username,
  ...
}:

let
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
        placeholder_text = <span foreground="##${
          builtins.substring 1 6 theme.palette.subtext0
        }">Password...</span>
        font_color = rgb(${builtins.substring 1 6 theme.palette.text})
        inner_color = rgb(${builtins.substring 1 6 theme.palette.base})
        # bordure du champ de mot de passe : blanc
        outer_color = rgb(ffffff)
        check_color = rgb(${builtins.substring 1 6 theme.palette.green})
        fail_color = rgb(${builtins.substring 1 6 theme.palette.red})
        shadow_passes = 2
    }

    label {
        monitor =
        text = cmd[update:1000] echo "$(date +'%H:%M')"
        color = rgba(${builtins.substring 1 6 theme.accentHex}, 1.0)
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
        active_border = "rgb(${builtins.substring 1 6 theme.accentHex})",
        inactive_border = "rgb(${builtins.substring 1 6 theme.palette.surface0})",
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
    config.max_fps = 120
    config.scrollback_lines = 10000
    config.audible_bell = 'Disabled'

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
  options.fyrr.wayle.configFile = lib.mkOption {
    type = lib.types.path;
    description = "config.toml de wayle propre au host (runtime.toml reste inscriptible par wayle)";
  };

  config = {
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
        ".config/matugen/apply-hypr-colors.sh".source = ../../config/matugen/apply-hypr-colors.sh;

        ".config/wezterm/wezterm.lua".source = weztermLua;

        ".config/fastfetch/config.jsonc".source = ../../config/fastfetch/config.jsonc;

        ".config/nushell/config.nu".source = ../../config/nushell/config.nu;
        ".config/nushell/env.nu".source = ../../config/nushell/env.nu;

        ".config/starship.toml".source = ../../config/starship/starship.toml;

        ".config/wayle/tombi.toml".source = ../../config/wayle/tombi.toml;
        ".config/wayle/config.toml".source = config.fyrr.wayle.configFile;
        ".config/wayle/schema.json".source = ../../config/wayle/schema.json;

        ".config/git/config".source = ../../config/git/config;

        ".config/rofi/config.rasi".source = ../../config/rofi/config.rasi;
        ".config/rofi/ayu-dark.rasi".source = ../../config/rofi/ayu-dark.rasi;
      };
    };
  };
}
