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

**desktop**

- **hyprland ignores `services.xserver.xkb`.** the session keyboard lives in
  `hyprland.lua`; the xkb option only covers sddm.
- **keybinds on digits use keycodes** (`code:10` … `code:19`). on azerty the
  unshifted top row is `& é " ...`, so `mainMod + 1` would never fire.
- **the nixos hyprland wrapper grants `cap_sys_nice`**, which puts glibc in
  secure mode: it strips `TZDIR` (and makes the process unreadable in `/proc`).
  `hyprland.lua` sets `TZDIR` back, otherwise every app falls back to utc.
- **hyprland ships no polkit agent.** `hyprpolkitagent` is exposed through
  `systemd.packages` and started from `hyprland.lua`, since
  `graphical-session.target` is never reached here.
- **`TAG+="uaccess"` udev rules must sort before `73-seat-late.rules`.**
  `services.udev.extraRules` writes `99-local.rules`, too late, so the gaming
  rules ship as `70-gaming.rules` through `services.udev.packages`.
- **workspaces are assigned in `hyprland.lua`**, the same file on navi
  and games. no app starts with the session. 1 is grok bot. a terminal
  stays on the current workspace. 2 is empty, for windows a demo opens from code. 3 is
  brave. 4 is steam games (`steam_app_<id>`), gamescope, and the
  steam and lutris windows. 5 is vesktop, equibop, signal and fsa. 6 is
  bottom and nvtop, each launched with its own class, and coolercontrol.
  gajim no longer has a reserved workspace. the old workspace 3
  chat grid is gone.
- **`pkexec` is not setuid by default** on current nixos
  (`security.polkit.enablePkexecWrapper`). use `sudo`.

**darwin**

- **`homebrew.onActivation.cleanup = "uninstall"`** removes any cask that is not
  in the declared list. brew now prints a deprecation warning for the underlying
  flag.
