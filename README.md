# nixos-config

> [!WARNING]
> this is my **personal** nix configuration, built from scratch as a learning
> project. it fits my own machines and habits, so most of it will not work out
> of the box for you.

this repo configures three machines: two nixos hosts and one macbook running
nix-darwin. [hjem](https://github.com/feel-co/hjem) manages the dotfiles in
symlink-only mode. the real config files live in `config/`, and hjem links them
into place.

commit and pull request rules are in [docs/conventions.md](docs/conventions.md).
a longer, denser version of this file for coding agents is in
[README_agent.md](README_agent.md).

## foreword

i'm learning linux and nix in the open, and this repo is where i practice. i
want to understand each piece, not assemble the flashiest setup, so i keep
things small and explicit. if a choice looks naive, it's probably where i was
in the learning curve when i made it.

## hosts

| name | machine | platform | gpu | role |
|---|---|---|---|---|
| `navi` | thinkpad x1 carbon gen 12 (meteor lake) | nixos | intel arc (integrated) | laptop, learning machine |
| `games` | asus tuf gaming h770-pro, i7-13700kf | nixos | nvidia rtx 4070 | desktop, gaming, dual boot with windows |
| `sommei` | macbook pro (m1 pro) | nix-darwin (`aarch64-darwin`) | apple (integrated) | daily driver for multimedia |

the two nixos hosts differ in a few places:

| | navi | games |
|---|---|---|
| hyprland scale / mode | 1.8 / preferred | 1.0 / `2560x1440@360` |
| keyboard | qwerty-fr (accents on AltGr), caps lock is super | qwerty-fr (accents on AltGr), caps lock is super |
| `mainMod` | `SUPER`, also on caps lock (`caps:super`) | `SUPER` on caps lock (`caps:super`, 60% keyboard) |
| wayle config | `config/wayle/config-navi.toml` | `config/wayle/config-games.toml` |
| extras | power management, `powertop` | nvidia (open kernel module, stable branch), steam with proton-ge, coolercontrol (`nct6775`), spicetify, openrgb (leds off at boot), sunshine |

`hyprland.lua` reads `/etc/hostname` to pick the per-host values. the wayle
file comes from a custom option, `fyrr.wayle.configFile`, declared in
`modules/desktop/options.nix`.

### streaming from games to the mac

sunshine on games streams the desktop to moonlight on the mac. when a stream
starts, the panel switches to the resolution the client asks for (1920x1080
for the mac's external display), at scale `1` and its highest refresh rate.
this only happens if the panel's edid lists that mode.

sunshine leaks vram on every session. to clean up, the undo step of its prep
command reloads hyprland, which restores `2560x1440@360`, and then restarts
sunshine. sunshine only runs that undo step when the moonlight app session
ends, not on a plain disconnect. so keep moonlight's "Quit app on host PC
after ending stream" option on. if it's off, or moonlight crashes, run this on
games:

```sh
hyprctl reload
systemctl --user restart sunshine
```

### sommei

sommei runs macos. nix-darwin handles the system config. homebrew covers the
gui apps that nix packages poorly on mac, and nix-homebrew installs and pins
homebrew itself. godot 4.5, jdk 17 and the android sdk for meta quest 3 exports
all come from nix. see [docs/godot.md](docs/godot.md).

## structure

```
nixos-config/
├── flake.nix              # inputs, and the navi, games and sommei hosts
├── flake.lock
├── .sops.yaml             # sops-nix age recipients (placeholders) and creation rules
├── justfile               # tasks: switch, build, fmt, lint, check, update
├── theme.nix              # colour palettes and `render`, used by the whole theme
├── treefmt.nix            # formatter config (nixfmt)
├── statix.toml            # linter exclusions
├── docs/                  # conventions, secrets (in french), gotchas, godot, resources
├── hosts/
│   ├── navi/{default,hardware}.nix
│   ├── games/{default,hardware,rgb-off}.nix
│   └── sommei/default.nix
├── modules/
│   ├── shared/            # nix settings and the sops age key (nixos and darwin)
│   ├── core/              # boot, locale, nix daemon, zram, networking, users (no gui)
│   ├── desktop/           # hyprland, sddm, audio, fonts, gtk/qt/cursor theming, printing, hjem
│   ├── hardware/          # intel, nvidia, bluetooth, health, coolercontrol
│   └── programs/          # cli, apps, office, gaming, spicetify, sunshine, ollama, godot-android
├── pkgs/                  # packages and scripts not in nixpkgs (sunshine-monitor, ...)
└── config/                # native dotfiles (hyprland.lua, wayle, gtk, kde, ...)
```

each host imports only the modules it needs. a module imports its own
dependencies, so `spicetify.nix` pulls in the spicetify-nix module itself.
shared modules set defaults with `lib.mkDefault`, and a host overrides them
with a plain assignment. i keep `lib.mkForce` for real emergencies.

sommei declares its own hjem block inline, because its paths and tools differ
from the nixos hosts. only sommei imports `modules/programs/godot-android.nix`.

## flake inputs

| input | purpose |
|---|---|
| `nixpkgs` | `nixos-unstable`, for every host including sommei |
| `nix-darwin` | macos system config for sommei |
| `hjem` | dotfile symlinks |
| `nix-homebrew` | installs and pins homebrew on sommei |
| `spicetify-nix` | patched spotify on games |
| `treefmt-nix` | formatter, and the format check in `nix flake check` |
| `sops-nix` | age-encrypted secrets on every host, plus `sops` and `age` in the dev shell |
| `fsa` | microphone processing on every host (a package on nixos, a module on sommei) |
| `hermes-agent` | hermes desktop on games |
| `msga` | native slack client on games |
| `ramiel` | the ramiel discord theme for vesktop and equibop (not a flake) |

when an input has its own `nixpkgs` or `nix-darwin` input, it follows ours, so
the lock file keeps one copy of each. the exception is `hermes-agent`, whose
upstream only tests its package against its own `nixpkgs`.

## theming

the desktop uses a theme i call ramiel: dark green-black surfaces, a teal
accent, muted text that brightens on hover, square corners, 2px borders, and
JetBrainsMono Nerd Font in a light weight. it looks like a tui. the vesktop
theme (`config/vesktop/ramiel.theme.css`) and my obsidian vault theme are the
reference versions.

there are only two warm colours, and both stay rare. the red-orange of the
angel's core (`#e8502a`) marks errors, destructive actions, mentions and do not
disturb. amber (`#d9c27a`) marks warnings and idle states.

### the palette file

`theme.nix` at the repo root holds three palettes: `ramiel` (the default),
`blood`, and `copland` (a serial experiments lain reference). the `variant`
string picks one.

every palette has the same 26 named colours (following the catppuccin naming)
and the 16 ansi colours. anything that reads `theme.palette.<key>` changes
colour when the variant changes.

`ramiel` is what matugen generates from the pinned `Ramiel-wall.png` (dark
scheme, tonal-spot), plus the red-orange and amber. here is how the matugen
roles map to the palette keys:

| palette key | matugen role |
|---|---|
| `base`, `mantle`, `surface0..2` | surfaces |
| `text` | on_surface |
| `subtext1` | body text |
| `subtext0` | outline |
| `mauve` (the accent slot), `green` | primary |
| `teal` | primary fixed |
| `blue` | tertiary |
| `lavender` | secondary |
| `maroon` | error |
| `red` | the core red-orange (not from matugen) |
| `yellow` | amber (not from matugen) |

`flake.nix` imports the file once and passes it to every host as `theme`
through `specialArgs`. there are two ways to use it.

1. nix code writes the config file directly. `modules/desktop/hjem.nix` does
   this for `wezterm.lua`, `hyprlock.conf`, `hypr-theme.lua` (the border
   fallback) and the wayle `[styling]` section. `modules/programs/spicetify.nix`
   does it for the spotify colour scheme.
2. a native file in `config/` has markers, and `theme.render <file>` fills
   them in. `@key@` becomes `#rrggbb`, `@key.hex@` becomes `rrggbb`,
   `@key.rgb@` becomes `r,g,b`, and `@variant@` becomes the variant name. valid
   keys are the 26 palette keys, `accent`, and `ansi0` to `ansi15`. starship,
   fastfetch, rofi, btm, the zed theme, `gtk.css` and kdeglobals work this way.
   the source files stay readable.

### build-time and runtime colours

`theme.nix` sets every colour at build time. on top of that, wayle runs
matugen on the wallpaper at runtime, and matugen recolours four things:
hyprland borders, rofi, the vesktop `--m-*` variables, and the wayle bar.

matugen only runs when the variant is dynamic (`theme.dynamic`, true for
`ramiel`). in that case wayle sets `theme-provider = "matugen"`,
`hyprland.lua` loads `matugen-colors.lua` first, and rofi imports
`matugen-colors.rasi`. `ramiel` is matugen's own output for the pinned
wallpaper, so both layers give the same colours unless i change the
wallpaper. with `blood` or `copland`, wayle keeps its static palette and
ignores the matugen files, even old ones left on disk.

| app | where its colours come from |
|---|---|
| hyprland borders | matugen (`matugen-colors.lua`), falling back to `hypr-theme.lua` |
| wayle bar | `[styling]` generated in `hjem.nix`, then matugen at runtime. square buttons and popovers |
| rofi | `config/rofi/config.rasi` (rendered), then `matugen-colors.rasi` |
| wezterm, hyprlock | generated in `hjem.nix` |
| starship, fastfetch | `config/starship/starship.toml`, `config/fastfetch/config.jsonc` (rendered, starship on sommei too) |
| btm (games) | `[styles]` in `config/bottom/bottom.toml` (rendered) |
| zed | `config/zed/theme.json`, installed as `~/.config/zed/themes/theme-nix.json` with the theme name `theme.nix` |
| gtk 3 and 4 | `adw-gtk3-dark` and libadwaita, recoloured by `config/gtk/gtk.css` and `gtk4.css`. dconf sets `prefer-dark`, the theme, icons, cursor and fonts (`modules/desktop/theming.nix`) |
| electron, brave, libadwaita dark mode | `color-scheme = prefer-dark` through xdg-desktop-portal-gtk |
| qt and kde apps (dolphin, kate, ark, kdenlive, ...) | `qt.platformTheme = "kde"` with the breeze style. colours, fonts, icons and terminal come from `config/kde/kdeglobals`, installed as `/etc/xdg/kdeglobals` |
| spotify (games) | `config/spicetify/ramiel/user.css` for layout, `customColorScheme` from `theme.nix` for colours |
| vesktop | `ramiel.theme.css` and matugen's `ramiel-colors.theme.css` |
| obsidian | its own ramiel theme in the vault, outside this repo |

kdeglobals goes in `/etc/xdg`, and gtk settings go in the system dconf
database. kde apps write to `~/.config/kdeglobals` (file dialog state, for
example), which would break a hjem symlink there. values set at user level
still override the system ones, key by key.

### fonts

JetBrainsMono Nerd Font is the interface font everywhere: gtk, qt, rofi,
terminals, vesktop and obsidian. the fontconfig defaults are:

- monospace: JetBrainsMono Nerd Font
- sans-serif: Inter (only web pages and documents use it)
- serif: DejaVu
- emoji: Noto Color Emoji

Noto CJK covers japanese.

### settings to set once in each app

these apps store their theme in files they rewrite themselves, so hjem can't
manage them. set them by hand after a fresh install:

- zed: run `theme selector: toggle` and pick `theme.nix`
- brave: appearance, theme `GTK` or `Classic`, mode `Device`
- signal, bitwarden, obsidian: theme `System` (follows `prefer-dark`)
- onlyoffice: interface theme `Dark`
- mumble: theme `Dark`

## daily workflow

`just` runs everything. run it with no argument to list the recipes.

```sh
just switch    # rebuild and activate this host (asks for sudo)
just build     # build only, no activation, no sudo
just fmt       # run nixfmt over every .nix file (writes changes)
just lint      # statix and deadnix
just check     # format check and lint, the same checks ci should run
just update    # nix flake update, then bump-release on artcraft-launcher and t3code-nightly
just bump-release <file>  # move a pkgs/ package to its latest github release (or nightly)
```

the recipes detect the platform with `uname` and read the machine name, so the
same command works on all three hosts. `switch` and `build` use
`justfile_directory()`, so you can run them from any subdirectory.

`fmt` fixes formatting, and `check` only reports it. `check` formats a copy of
the sources inside the nix sandbox and fails if anything changed, so it never
writes to the repo. my usual loop is:

1. `git pull --rebase`
2. edit
3. `just fmt`
4. `just check`
5. `just build`
6. commit
7. `just switch`

`nix store diff-closures /run/current-system ./result` compares the running
system with the new build. after a refactor it should print nothing, which
means the code changed but the system didn't. before an update, it lists
every package whose version will change.

### rebuilding by hand

```sh
# nixos (navi, games)
sudo nixos-rebuild switch --flake .#<hostname>

# darwin (sommei). activation has to run as root.
sudo darwin-rebuild switch --flake .#sommei
```

`just switch` also sets `NIX_REMOTE=daemon` on nixos. this makes builds go
through the daemon at idle cpu priority. a plain `sudo nixos-rebuild` builds as
root at normal priority.

on macos, the flake attribute has to match `scutil --get LocalHostName`. don't
use the output of `hostname`, because dhcp or mdns can change it.

after editing `inputs`, `nix flake lock` updates the lock for the new inputs
and leaves the others alone. `nix flake update` bumps everything.

### checking that a host matches the repo

```sh
just build
readlink -f /run/current-system              # the running system
readlink -f result                           # what the repo builds
readlink -f /nix/var/nix/profiles/system     # what the next boot starts
```

if all three paths are the same, the machine matches the repo now and will
still match after a reboot. if a rebuild breaks booting, pick the previous
generation in the systemd-boot menu.

### development shell

```sh
nix develop
```

this gives you `nixd` (language server), `nixfmt`, `statix`, `deadnix`,
`just`, `sops` and `age` without installing them system-wide. secrets use
sops-nix, and [docs/secrets.md](docs/secrets.md) (in french) explains how to
edit them.

## state that nix does not manage

a fresh install restores the config but not the following. redo these by hand:

| what | where | how |
|---|---|---|
| tailscale identity | `/var/lib/tailscale` | `sudo tailscale up` |
| mullvad lan sharing | mullvad settings | `mullvad lan set allow`. without it, tailscale goes through a derp relay while mullvad is on |
| windows clock (games dual boot) | windows registry | set `RealTimeIsUniversal = 1` so both systems read the hardware clock as utc |
| wayle gui tweaks | `~/.config/wayle/runtime.toml` | copy anything worth keeping into `config/wayle/config-<host>.toml` |
| ssh keys | `~/.ssh` | generate new ones and add them to github |
| sops age host key | `/var/lib/sops-nix/key.txt` | `age-keygen` as root, see `docs/secrets.md` |
| sops age user key | `~/.config/sops/age/keys.txt` | `age-keygen`. back it up off the machine. if you lose it and no host key remains, the secrets are gone |
| mumble audio backend (nixos) | `~/.config/Mumble/Mumble/mumble_settings.json` | set input and output to `PulseAudio`. otherwise pipewire 1.4 or newer gets mumble 1.5 killed with SIGKILL |
| game prefixes | `~/Games`, steam library | reinstall from steam or lutris |

## gotchas

pitfalls i hit with nix, hjem, the desktop and darwin are in
[docs/gotchas.md](docs/gotchas.md).

## system

- network: networkmanager, systemd-resolved, mullvad (daemon and gui), and
  tailscale. navi keeps tailscale's shields-up on. games turns it off, so the
  tailnet ACLs decide what gets in, since tailscaled accepts traffic on
  tailscale0 before the nixos firewall sees it. this repo doesn't configure the
  tailscale app on the mac.
- memory: zram swap (zstd, up to 50% of ram), no disk swap, no hibernation.
  `vm.swappiness` is 180 and `vm.page-cluster` is 0 to suit zram.
- desktop: sddm (where-is-my-sddm-theme, the lock wallpaper, colours from
  `theme.nix`) starts hyprland. then wezterm, nushell as the login shell with
  starship, the wayle bar, hyprlock and hypridle (locks when idle and before
  sleep), and hyprpolkitagent.
- console: the initrd loads the terminus font (`ter-v32n` on navi, `ter-v24n`
  on games), and the tty colours come from `theme.ansi16`.
- printing: cups.
- nix: garbage collection every week for anything older than 7 days, store
  auto-optimisation, and builds and gc at idle cpu priority.
- locale: `en_US.UTF-8` with french regional settings, timezone `Europe/Paris`.
- sommei: touch id for sudo, and declarative settings for the dock, finder,
  trackpad, key repeat and screenshots.

## resources

[docs/resources.md](docs/resources.md) explains what keeps each host light, and
why.

## known gaps

- **no secrets yet.** sops-nix is set up on all three hosts, but there are no
  secrets in it, and the age recipients in `.sops.yaml` are still placeholders.
  see `docs/secrets.md` for the workflow.
- **`just check` doesn't build the hosts.** it evaluates them, so a wrong
  option or a typo fails, but a package that doesn't compile still passes.
- **a few theme pieces live outside `theme.nix`.** kitty (sommei only) keeps
  its own eva24 file. the obsidian ramiel theme lives in the vault. vesktop's
  fallback colours are written by hand, though matugen overrides them anyway.
  breeze (qt) keeps its small rounded corners.
- **git history has several author names.** the current identity is in
  `config/git/config`, which hjem links into place.
- **no disk encryption.** navi uses plain ext4 and games uses btrfs, neither
  with luks. adding it means backing up, reinstalling on luks, and running
  `systemd-cryptenroll --tpm2-device=auto` to unlock at boot without a
  password.
- **no declarative backups.** restic is only installed as a package on sommei.
  a `services.restic.backups` job first needs a repository and its password
  stored as a sops secret.
