# nixos-config

> [!NOTE]
> this github repo is only a mirror. the real repo lives on my private,
> self-hosted [forgejo](https://forgejo.org) instance, so this mirror can
> sometimes lag behind and not be up to date.

> [!WARNING]
> this is my **personal** nix configuration, built from scratch as a learning
> project. it is tailored to my own machines and habits, so most of it will not
> work out of the box for you.

three machines share this repo: two nixos hosts and one macbook under
nix-darwin. dotfiles are managed by [hjem](https://github.com/feel-co/hjem) in
symlink-only mode: native config files in `config/` are the single source of
truth, and hjem just links them into place.

commit and pull request rules: [docs/conventions.md](docs/conventions.md).

## foreword

i'm learning linux and nix in the open. this repo is the practice ground. the
goal is to understand rather than to assemble the flashiest setup, so things are
kept deliberately small and explicit. if a choice looks naive, it probably
reflects where i was in the learning curve when i made it.

## hosts

| name | machine | platform | gpu | role |
|---|---|---|---|---|
| `navi` | thinkpad x1 carbon gen 12 (meteor lake) | nixos | intel arc (integrated) | laptop, learning machine |
| `games` | asus tuf gaming h770-pro, i7-13700kf | nixos | nvidia rtx 4070 | desktop, gaming, dual boot with windows |
| `sommei` | macbook pro (m1 pro) | nix-darwin (`aarch64-darwin`) | apple (integrated) | multimedia daily driver |

the two nixos hosts differ in a few places:

| | navi | games |
|---|---|---|
| hyprland scale / mode | 1.8 / preferred | 1.0 / `2560x1440@360` |
| keyboard | qwerty-fr (accents on AltGr), caps lock is super | qwerty-fr (accents on AltGr), caps lock is super |
| `mainMod` | `SUPER`, also via caps lock (`caps:super`) | `SUPER` via caps lock (`caps:super`, 60% keyboard) |
| wayle config | `config/wayle/config-navi.toml` | `config/wayle/config-games.toml` |
| theme variant | `ramiel-orange` (fixed) | `ramiel` (dynamic via matugen) |
| extras | power management (`upower`, `power-profiles-daemon`, `thermald`, 75–80% battery charge thresholds), `powertop`, intel VA-API/QSV (`intel-media-driver`, `vpl-gpu-rt`) + `mpv` hwdec, `ext4` (`noatime,commit=60`) | nvidia (open kernel module, stable branch, 170 W power limit reapplied after suspend), steam + proton-ge, coolercontrol (`nct6775`), spicetify, openrgb (leds off at boot), sunshine, ollama, remotion, `btrfs` (`compress=zstd:1,noatime` + monthly scrub), Wake-on-LAN |

per-host values in `hyprland.lua` are picked by reading `/etc/hostname`. the
wayle file is selected through a custom option, `fyrr.wayle.configFile`,
declared in `modules/desktop/options.nix` (alongside `fyrr.hyprlock.battery`
for showing the laptop battery level on the lock screen and
`fyrr.wallpapers.{desktop,lock}` for per-host desktop and lockscreen/sddm
wallpapers).

### streaming from games to the mac

sunshine on `games` streams the desktop to moonlight on the mac. when a stream
starts, the panel switches to the resolution the client asks for (`1920x1080`
for the mac's external display), at scale `1` and its highest refresh rate.
this only happens if the panel's edid lists that mode.

sunshine leaks vram on every session. to clean up, the undo step of its prep
command reloads hyprland, which restores `2560x1440@360`, and then restarts
sunshine. sunshine only runs that undo step when the moonlight app session
ends, not on a plain disconnect. so keep moonlight's "Quit app on host PC
after ending stream" option on. if it's off, or moonlight crashes, run this on
`games`:

```sh
hyprctl reload
systemctl --user restart sunshine
```

### sommei

`sommei` runs macos. nix-darwin handles the declarative system config, and
homebrew — itself installed and pinned by `nix-homebrew` — covers the gui casks
that nix handles poorly on mac. godot 4.5, jdk 17 and the android toolchain for
meta quest 3 exports are nix packages; see [docs/godot.md](docs/godot.md).

to set up a new mac from this repo, from factory reset to the first
`just switch`, follow [docs/darwin-bootstrap.md](docs/darwin-bootstrap.md).

## structure

```
nixos-config/
├── flake.nix              # inputs + declares navi, games, sommei
├── flake.lock
├── .sops.yaml             # sops-nix age recipients (placeholders) + creation rules
├── justfile               # task runner: switch, build, fmt, lint, eval, check, doctor, scan, bump, update
├── theme.nix              # colour palettes + `render`, single source for the whole theme
├── treefmt.nix            # formatter config (nixfmt)
├── statix.toml            # linter exclusions
├── docs/                  # conventions, darwin-bootstrap, godot, gotchas, resources, secrets (in French)
├── hosts/
│   ├── navi/{default,hardware}.nix
│   ├── games/{default,hardware,rgb-off}.nix
│   └── sommei/default.nix
├── modules/
│   ├── shared/            # nix settings + sops age key (nixos and darwin)
│   ├── core/              # boot, locale, nix daemon, zram, networking, users (no gui)
│   ├── desktop/           # hyprland, sddm, audio, fonts, theming (gtk, qt, cursor), printing, wallpapers, options, hjem
│   ├── hardware/          # intel, nvidia, nvidia-power, bluetooth, health, coolercontrol
│   └── programs/          # cli, apps, office, craft, timon, gaming, spicetify, sunshine, ollama, remotion, godot-android (sommei)
├── pkgs/                  # packages and scripts outside nixpkgs (sunshine-monitor, craft-app*, ladybird*, timon*, see*, t3code-nightly, horizon-launcher, artcraft-launcher, mistral-vibe, sm64coopdx, grok-bot, power-menu, apply-hypr-colors)
└── config/                # native dotfiles (hyprland.lua, wayle, gtk, kde, rofi, starship, fastfetch, bottom, zed, zen, kitty, fish, nushell, git, mpv, ...)
```

modules are opt-in: each host imports only what it needs, and a module imports
its own dependencies (e.g. `spicetify.nix` pulls the `spicetify-nix` module
itself). shared modules propose values with `lib.mkDefault`; a host overrides
them plainly, and `lib.mkForce` stays for real emergencies.

the darwin host declares its own hjem block inline, since its paths and its
subset of tools differ. `modules/programs/godot-android.nix` is imported only
by `sommei`.

## flake inputs

| input | purpose |
|---|---|
| `nixpkgs` | `nixos-unstable`, for every host including `sommei` |
| `nix-darwin` | macos system management for `sommei` |
| `hjem` | dotfile symlinks |
| `nix-homebrew` | installs and pins homebrew itself on `sommei` |
| `spicetify-nix` | patched spotify on `games` |
| `treefmt-nix` | formatter + `nix flake check` gate |
| `sops-nix` | age-encrypted secrets on every host; `sops` and `age` in the dev shell |
| `fsa` | mic processing on every host (package on nixos, darwin module on `sommei`) |
| `msga` | native slack client on `games` |
| `ardia` | chromium-based browser (`x86_64-linux` upstream binary on `navi` and `games`) |
| `ramiel` | ramiel discord theme for vesktop and equibop (`flake = false`) |

inputs that ship a `nixpkgs` or `nix-darwin` input follow ours, so the lock
keeps a single copy of each. `sops-nix` follows `nixpkgs`.

## theming

the whole desktop follows **ramiel**: dark green-black surfaces, a teal accent,
muted text that brightens on hover, square corners, 2px borders and
JetBrainsMono Nerd Font in a light weight, in a tui style. the reference
implementations are the vesktop theme (`config/vesktop/ramiel.theme.css`) and
the obsidian vault theme.

there are only two warm colours, and both stay rare. the red-orange of the
angel's core (`#e8502a`) marks errors, destructive actions, mentions and do not
disturb. amber (`#d9c27a`) marks warnings and idle states.

### palette: `theme.nix`

`theme.nix` sits at the repo root and holds five palettes: `ramiel` (default,
used on `games`), `ramiel-orange` (used on `navi`, derived from `ehmvi/ramiel`
`palettes/orange.css` / matugen seed `#f08c28`), `herbanium` (light aged-vellum
and sepia-ink palette, used on `sommei`), `blood` and `copland` (a serial
experiments lain reference). `flake.nix` calls `theme.nix` per host through
`mkHost`'s `themeVariant` argument.

every palette exposes the same 26 semantic keys (catppuccin convention) plus
the 16 ansi colours, so any consumer that interpolates `theme.palette.<key>`
rethemes automatically. `ramiel` is matugen's output on the pinned
`Ramiel-wall.png` (dark scheme, tonal-spot), plus the core red-orange and amber
accents. `ramiel-orange` uses the same role mapping on matugen's `#f08c28`
tonal-spot output, with a crimson core (`#ec3b52`) so errors stay distinct from
the orange accent. here is how the matugen roles map to the palette keys:

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
| `red` | the core accent (not from matugen) |
| `yellow` | amber (not from matugen) |

`flake.nix` instantiates `theme.nix` per host and passes it as `theme` through
`specialArgs`. there are two ways to consume it:

1. **inline nix**: `wezterm.lua`, `hyprlock.conf`, `hypr-theme.lua` (border
   fallback) and the wayle `[styling]` section are written in
   `modules/desktop/hjem.nix`; the spotify colour scheme in
   `modules/programs/spicetify.nix`.
2. **native files with markers**: `theme.render <file>` reads a file from
   `config/` and fills `@key@` (`#rrggbb`), `@key.hex@` (`rrggbb`),
   `@key.rgb@` (`r,g,b`), `@variant@` and `@appearance@` (`light` or `dark`).
   valid keys are the 26 palette keys, `accent` and `ansi0`..`ansi15`. used for
   starship, fastfetch, rofi, btm, kitty, the zed theme, `gtk.css` and
   `kdeglobals`. the source files stay readable as is.

### build-time and runtime colours (two layers, one owner each)

| layer | when | owns |
|---|---|---|
| `theme.nix` | build time | everything static, below |
| matugen | runtime, driven by wayle on the wallpaper | hyprland borders, rofi colours, vesktop `--m-*` vars, wayle bar palette |

matugen only runs when the variant is dynamic (`theme.dynamic`, true for
`ramiel`). wayle then uses `theme-provider = "matugen"`, `hyprland.lua` prefers
`matugen-colors.lua` and rofi imports `matugen-colors.rasi`. since `ramiel` is
matugen's own output for the pinned wallpaper, both layers agree; they only
diverge if the wallpaper changes. with `ramiel-orange`, `blood`, `copland` or
`herbanium`, wayle keeps its static palette and the matugen files, even stale
ones, are ignored.

| app | where its colours come from |
|---|---|
| hyprland borders | matugen (`matugen-colors.lua`) when dynamic, otherwise `hypr-theme.lua` |
| wayle bar | `[styling]` generated in `hjem.nix`, then matugen at runtime if dynamic. square buttons and popovers |
| rofi | `config/rofi/config.rasi` (rendered), plus `matugen-colors.rasi` if dynamic |
| wezterm, hyprlock | generated in `hjem.nix` |
| kitty (`sommei`) | `config/kitty/theme.conf` (rendered, reloaded with `SIGUSR1` on switch) |
| starship, fastfetch | `config/starship/starship.toml`, `config/fastfetch/config.jsonc` (rendered, on `sommei` too) |
| btm (`games`) | `[styles]` in `config/bottom/bottom.toml` (rendered) |
| zed | `config/zed/theme.json` → `~/.config/zed/themes/theme-nix.json`, theme name `theme.nix` (on `sommei` too) |
| gtk 3 / 4 | `adw-gtk3-dark` + libadwaita, recoloured by `config/gtk/gtk.css` and `gtk4.css`; dconf sets `prefer-dark`, the theme, icons, cursor and fonts (`modules/desktop/theming.nix`) |
| electron, brave, libadwaita dark mode | `color-scheme = prefer-dark` through `xdg-desktop-portal-gtk` |
| qt / kde (dolphin, kate, ark, kdenlive…) | `qt.platformTheme = "kde"` with the breeze style; colours, fonts, icons and terminal come from `config/kde/kdeglobals`, installed as `/etc/xdg/kdeglobals` |
| spotify (`games`) | `config/spicetify/ramiel/user.css` (structure only) + `customColorScheme` from `theme.nix` |
| vesktop | `ramiel.theme.css` + matugen's `ramiel-colors.theme.css` on `games`; fixed `ramiel-orange.theme.css` on `navi` |
| equibop | fixed `ramiel-orange.theme.css` |
| t3 code (`navi`) | `ramiel-orange.json` copied (`type = "copy"`, t3 code opens themes with `O_NOFOLLOW`) from `inputs.ramiel` into `~/.t3/userdata/themes/` |
| obsidian | its own ramiel theme in the vault, outside this repo |

`kdeglobals` goes in `/etc/xdg` and gtk settings in the system dconf database
on purpose: kde apps rewrite `~/.config/kdeglobals` (file dialog state, for
example), and a hjem symlink there would break. user-level values still
override the system ones, key by key.

### fonts

JetBrainsMono Nerd Font is the interface font everywhere: gtk, qt, rofi,
terminals, vesktop and obsidian. fontconfig defaults:

- monospace: JetBrainsMono Nerd Font
- sans-serif: Inter (only web pages and documents use it)
- serif: DejaVu
- emoji: Noto Color Emoji

Noto CJK covers japanese.

### one-time steps in app uis

these apps store their theme in files they rewrite themselves, so hjem cannot
manage them. set them by hand after a fresh install:

- zed: `theme selector: toggle` → `theme.nix`
- brave: appearance → theme `GTK` or `Classic`, mode `Device`
- signal, bitwarden, obsidian: theme `System` (follows `prefer-dark`)
- onlyoffice: interface theme `Dark`
- mumble: theme `Dark`

## daily workflow

`just` is the entry point. run it with no argument to list the recipes.

```sh
just switch                # rebuild + activate this host (asks for sudo)
just build                 # build only, no activation, no sudo
just fmt                   # run nixfmt over every .nix file (writes)
just lint                  # statix + deadnix + shellcheck of sommei postActivation script
just eval                  # evaluate all 3 hosts without building
just check                 # format check + lint + eval, mirrors what ci should do
just doctor                # read-only health check on the running host (failed units, broken store links, mimeapps, hw guards, wayle log)
just scan                  # scan full git history with gitleaks
just bump <input>          # update a single flake input (e.g. just bump nixpkgs)
just update                # nix flake update + bump-release on tracked pkgs + bump-craft + bump-ladybird
just bump-ladybird         # bump pkgs/ladybird*.nix from download.ladybird.org and the apt index
just bump-craft            # bump pkgs/craft-apps.json from github SHA256SUMS.txt
just bump-release <file>   # move a pkgs/ package to its latest github release (or nightly)
```

the recipes detect the platform with `uname` and read the machine name on their
own, so the same command works on all three hosts. `switch` and `build` use
`justfile_directory()`, so they work from any subdirectory.

order matters: **`fmt` corrects, `check` only verifies.** `check` builds a
derivation that formats a copy of the sources in the nix sandbox and fails on
any diff — it never writes to the repo. the usual loop is:

```
git pull --rebase → edit → just fmt → just check → just build → commit → just switch
```

two habits worth keeping:

- **after a refactor**, `nix store diff-closures /run/current-system ./result`
  must print nothing: same system, cleaner code.
- **before an update lands**, the same command lists every package whose version
  changes.

### rebuilding by hand

```sh
# nixos (navi, games)
sudo nixos-rebuild switch --flake .#<hostname>

# darwin (sommei) — activation has to run as root
sudo darwin-rebuild switch --flake .#sommei
```

on a mac without nix-darwin yet, see
[docs/darwin-bootstrap.md](docs/darwin-bootstrap.md).

`just switch` also sets `NIX_REMOTE=daemon` on nixos. this makes builds go
through the daemon at idle cpu priority. a plain `sudo nixos-rebuild` builds as
root at normal priority.

on macos, the flake attribute must match `scutil --get LocalHostName`, not the
output of `hostname` — dhcp or mdns can overwrite `hostname`.

after editing `inputs`, `nix flake lock` updates the lock for the new inputs
and leaves the others alone. `nix flake update` bumps everything.

### checking that a host matches the repo

```sh
just build
readlink -f /run/current-system              # the running system
readlink -f result                           # what the repo builds
readlink -f /nix/var/nix/profiles/system     # what the next boot starts
```

all three paths identical = the machine matches the repo now and will still
match after a reboot. if a rebuild breaks booting, pick the previous generation
in the systemd-boot menu.

### development shell

```sh
nix develop
```

gives `nixd` (language server), `nixfmt`, `statix`, `deadnix`, `just`, `sops`
and `age` without installing them system-wide. secrets use `sops-nix`, and
[docs/secrets.md](docs/secrets.md) (in French) explains how to edit them.

## state that nix does not manage

a fresh install restores the config, not the following. redo these by hand:

| what | where | how |
|---|---|---|
| tailscale identity | `/var/lib/tailscale` | `sudo tailscale up` |
| mullvad lan sharing | mullvad settings | `mullvad lan set allow` (otherwise tailscale goes through a derp relay when mullvad is on) |
| windows clock (`games` dual boot) | windows registry | set `RealTimeIsUniversal = 1` so both systems read the hardware clock as utc |
| wayle gui tweaks | `~/.config/wayle/runtime.toml` | copy anything worth keeping into `config/wayle/config-<host>.toml` |
| ssh keys | `~/.ssh` | generate new ones and add them to github |
| sops age host key | `/var/lib/sops-nix/key.txt` | `age-keygen` as root; see `docs/secrets.md` |
| sops age user key | `~/.config/sops/age/keys.txt` | `age-keygen`; back it up off the machine — losing it makes secrets unrecoverable unless a host key remains |
| mumble audio backend (nixos) | `~/.config/Mumble/Mumble/mumble_settings.json` | set input and output to `PulseAudio`, otherwise mumble 1.5 gets SIGKILLed with pipewire >= 1.4 |
| game prefixes | `~/Games`, steam library | reinstall from steam or lutris |

## gotchas

nix, hjem, desktop and darwin pitfalls met in this repo:
[docs/gotchas.md](docs/gotchas.md).

## system

- **network**: networkmanager, systemd-resolved, mullvad (daemon + gui), and
  tailscale. `navi` keeps tailscale's shields-up on. `games` turns it off, so
  tailnet ACLs are the gate there, since `tailscaled` accepts traffic on
  `tailscale0` before the nixos firewall sees it. this repo doesn't configure
  the tailscale app on the mac.
- **memory**: zram swap (zstd, up to 50% of ram), no disk swap, no hibernation.
  `vm.swappiness` is 180 and `vm.page-cluster` is 0 to suit zram.
- **desktop**: sddm (`where-is-my-sddm-theme`, the lock wallpaper, colours from
  `theme.nix`) starts hyprland. then wezterm, nushell as the login shell with
  starship, the wayle bar, hyprlock and hypridle (locks when idle and before
  sleep), and hyprpolkitagent.
- **console**: the initrd loads the terminus font (`ter-v32n` on `navi`,
  `ter-v24n` on `games`), and the tty colours come from `theme.ansi16`.
- **printing**: cups.
- **nix**: weekly garbage collection for anything older than 7 days, weekly
  store optimisation, and builds and gc at idle cpu priority.
- **locale**: `en_US.UTF-8` with french regional settings, timezone
  `Europe/Paris`.
- **`sommei`**: touch id for sudo (including inside tmux/cmux via `reattach`),
  macos application firewall with stealth mode, caps lock remapped to left
  command (`hidutil`), and declarative settings for the dock, finder, trackpad,
  key repeat and screenshots.

## resources

what keeps each host light, and why: [docs/resources.md](docs/resources.md).

## known gaps

- **no secrets yet.** `sops-nix` is wired on all three hosts, but no secret is
  defined yet and the age recipients in `.sops.yaml` are still placeholders.
  workflow: `docs/secrets.md`.
- **`just check` evaluates the hosts but does not build them**: a wrong option
  or a typo fails, a package that fails to compile still passes.
- **a few theme pieces stay outside `theme.nix`.** the obsidian ramiel theme
  lives in the vault. vesktop's
  fallback colours are hand-written, though matugen overrides them anyway.
  breeze (qt) keeps its small rounded corners.
- **git history carries several author names.** the current identity is
  declared in `config/git/config`, linked by hjem.
- **no disk encryption.** `navi` uses plain ext4 and `games` uses btrfs,
  neither with luks. encrypting means reformatting: back up, reinstall on luks,
  then `systemd-cryptenroll --tpm2-device=auto` to unlock at boot without a
  password.
- **no declarative backups.** `restic` is only installed as a package on
  `sommei`. a `services.restic.backups` job first needs a repository and its
  password stored as a sops secret.
