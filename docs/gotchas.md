# gotchas

**nix and flakes**

- **flakes only see git-tracked files.** after creating a file, `git add` before
  rebuilding, or nix fails with `Path '...' does not exist in the Git repository`.
- **read nix errors from the bottom.** look for `Failed assertions:` or the last
  `error:`; everything above is the evaluation trace.
- **`permittedInsecurePackages` pins an exact version** and silently stops
  applying at the next bump.
- **deadnix flags unused arguments** (`{ pkgs, lib, ... }:`). removing the last
  use of `lib` or `inputs` means removing it from the header too.
- **bootstrapping a tool that drives rebuilds** is circular: adding `just` to a
  host's packages does nothing until a rebuild has run. break the loop once with
  `nix run nixpkgs#just -- switch`.

**dotfiles (hjem)**

- **hjem links point into the nix store**, not into the live repo. editing a
  dotfile and reloading the tool is not enough; the change lands after a rebuild.
  `hyprctl reload` then re-runs `hyprland.lua` from `~/.config/hypr/hyprland.lua`,
  including its `dofile` of `matugen-colors.lua`. a logout is not required.
- **hjem links files, not directories**, so it does not clobber things like
  fish's `conf.d/` or `functions/`.
- **never declare a file the app rewrites itself.** the app replaces the symlink
  with a real file and the next rebuild conflicts with it. seen with zen's
  `profiles.ini` (seeded once by an activation script on `sommei`), wayle's
  `runtime.toml` (left to wayle, only `config.toml` is declared) and kde's
  `kdeglobals` (the colour scheme goes to `/etc/xdg/kdeglobals` instead; kde
  apps read both, `~/.config` first). same for zed's `settings.json`: only the
  theme file in `~/.config/zed/themes/` is linked.
- **some apps reject symlinks (`O_NOFOLLOW`).** t3 code opens files in
  `~/.t3/userdata/themes/` with `O_NOFOLLOW` and silently drops symlinks. use
  `type = "copy"` (with `permissions = "644"` and `clobber = true`) in hjem
  for those files instead of the default symlink.

**desktop**

- **hyprland ignores `services.xserver.xkb`.** the session keyboard lives in
  `hyprland.lua`; the xkb option only covers sddm.
- **keybinds on digits use keycodes** (`code:10` … `code:19`). on azerty the
  unshifted top row is `& é " ...`, so `mainMod + 1` would never fire.
- **the nixos hyprland wrapper grants `cap_sys_nice`**, which puts glibc in
  secure mode: it strips `TZDIR` (and makes the process unreadable in `/proc`).
  `hyprland.lua` sets `TZDIR` back, otherwise every app falls back to utc.
- **hyprland ships no polkit agent.** `hyprpolkitagent` is exposed through
  `systemd.packages`, which installs the unit but ignores its
  `WantedBy=graphical-session.target`, so `hyprland.lua` starts it. uwsm
  does reach that target, so a `wantedBy` on the unit would work too.
- **`TAG+="uaccess"` udev rules must sort before `73-seat-late.rules`.**
  `services.udev.extraRules` writes `99-local.rules`, too late, so the gaming
  rules ship as `70-gaming.rules` through `services.udev.packages`.
- **workspaces are assigned in `hyprland.lua`**, the same file on navi
  and games. no app starts with the session. a terminal stays on the
  current workspace. 1 is grok bot. 2 is t3 code (`com.t3tools.T3Code`,
  or `t3code` from its `.desktop`). 3 has no rule. 4 is brave. 5 is
  vesktop, equibop, signal and fsa. 6 is games: steam or umu-proton games
  (`steam_app_<id>`, `steam_app_default`) and gamescope. 7 is the launchers: steam, lutris and
  battle.net. 10 is monitoring: bottom and nvtop, each launched with its
  own class (`ws10-btm`, `ws10-nvtop`), and coolercontrol. gajim has no
  workspace.
- **`pkexec` is not setuid by default** on current nixos
  (`security.polkit.enablePkexecWrapper`). use `sudo`.
- **`~/.config/mimeapps.list` wins over `/etc/xdg/mimeapps.list`.** apps
  write their own defaults there ("set as default browser"), so a type
  declared in `xdg.mime.defaultApplications` can stay ignored. check with
  `xdg-mime query default <type>` and drop the stale line from the user file.

**darwin**

- **`homebrew.onActivation.cleanup = "uninstall"`** removes any cask that is not
  in the declared list. brew now prints a deprecation warning for the underlying
  flag.
- **don't add fish to `/etc/shells` by hand before the first switch.** nix-darwin
  only replaces `/etc/shells` when it matches the stock macos file. an edited
  one aborts activation with `Unexpected files in /etc`, and has to be renamed
  to `/etc/shells.before-nix-darwin` first. the fish shell comes from
  `environment.shells` anyway.
