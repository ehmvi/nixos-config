# nixos-config

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
| `navi` | thinkpad x1 carbon gen 12 (meteor lake) | nixos | intel arc (integrated) | learning machine, laptop |
| `games` | asus tuf gaming h770-pro, i7-13700kf | nixos | nvidia rtx 4070 | desktop, gaming, dual boot with windows |
| `sommei` | macbook pro (m1 pro) | nix-darwin (`aarch64-darwin`) | — | multimedia daily driver |

| | navi | games |
|---|---|---|
| hyprland scale / mode | 1.8 / preferred | 1.0 / `2560x1440@360` |
| keyboard | `us,fr` | `us` only |
| `mainMod` | `SUPER` | `SUPER` via caps lock (`caps:super`, 60% keyboard) |
| wayle config | `config/wayle/config-navi.toml` | `config/wayle/config-games.toml` |
| extras | power management, `powertop` | nvidia (open kernel module, stable branch), steam + proton-ge, coolercontrol (`nct6775`), spicetify, openrgb (leds off at boot), sunshine (stream the desktop to moonlight on the mac) |

per-host values in `hyprland.lua` are picked by reading `/etc/hostname`. the
wayle file is selected through a custom option, `fyrr.wayle.configFile`,
declared in `modules/desktop/hjem.nix`. on games, a moonlight stream
switches the panel to the resolution the client asks for (1920×1080 for
the mac's external display), at its highest refresh rate and scale `1`,
when the panel's edid has that mode. sunshine leaks vram on every moonlight
session, so the prep-command undo reloads the lua, which restores
`2560x1440@360`, then restarts sunshine. sunshine runs that undo when the
moonlight app session ends, not on a plain disconnect, so moonlight's "Quit
app on host PC after ending stream" has to stay on. if that option is off
or moonlight crashes, run `hyprctl reload` and
`systemctl --user restart sunshine` on games.

**sommei** runs macos. nix-darwin handles the declarative system config, and
homebrew — itself installed and pinned by nix-homebrew — covers the gui casks
that nix handles poorly on mac. godot 4.5 and the android toolchain for a meta
quest 3 export are nix packages; see [docs/godot.md](docs/godot.md).
Kopuz comes from its own flake, so `nix flake update` follows upstream while
nixpkgs lags. nix-darwin links `Kopuz.app` into `/Applications/Nix Apps`.

## structure

```
nixos-config/
├── flake.nix              # inputs + declares navi, games, sommei
├── flake.lock
├── .sops.yaml             # sops-nix age recipients (placeholders) + creation rules
├── justfile               # task runner: switch, build, fmt, lint, check, update
├── theme.nix              # colour palette, single source for the whole theme
├── treefmt.nix            # formatter config (nixfmt)
├── statix.toml            # linter exclusions
├── docs/                  # conventions, secrets (in French), gotchas, godot, resources
├── hosts/
│   ├── navi/{default,hardware}.nix
│   ├── games/{default,hardware}.nix
│   └── sommei/default.nix
├── modules/
│   ├── shared/            # nix settings + sops age key (nixos and darwin)
│   ├── core/              # boot, locale, nix daemon, zram, networking, users (no gui)
│   ├── desktop/           # hyprland, sddm, audio, fonts, cursor, printing, hjem
│   ├── hardware/          # intel, nvidia, bluetooth, health, coolercontrol
│   └── programs/          # cli, apps, office, gaming, spicetify, sunshine, ollama, godot-android (sommei)
├── pkgs/                  # packages and scripts outside nixpkgs (sunshine-monitor, ...)
└── config/                # native dotfiles (hyprland.lua, wayle, kitty, ...)
```

modules are opt-in: each host imports only what it needs, and a module imports
its own dependencies (e.g. `spicetify.nix` pulls the spicetify-nix module
itself). shared modules propose values with `lib.mkDefault`; a host overrides
them plainly, `lib.mkForce` stays for real emergencies.

the darwin host declares its own hjem block inline, since its paths and its
subset of tools differ. `modules/programs/godot-android.nix` is imported only
by `sommei`.

## godot on sommei

godot, jdk 17 and the android sdk for the quest 3 export, all from nix: [docs/godot.md](docs/godot.md).

## flake inputs

| input | purpose |
|---|---|
| `nixpkgs` | `nixos-unstable` (also used by `sommei`) |
| `nix-darwin` | macos system management for `sommei` |
| `hjem` | dotfile symlinks |
| `nix-homebrew` | installs and pins homebrew itself on `sommei` |
| `spicetify-nix` | patched spotify on `games` |
| `treefmt-nix` | formatter + `nix flake check` gate |
| `sops-nix` | age-encrypted secrets on every host; `sops` and `age` in the dev shell |
| `kopuz` | music player from upstream. on `sommei` it is a Nix app; `navi` and `games` install the same package |

inputs that ship a `nixpkgs` or `nix-darwin` input follow ours, so the lock
keeps a single copy of each. `kopuz` keeps its own nixpkgs: `kopuz.cachix.org`
only stores binaries built against that copy, and following ours would compile
the player locally. sops-nix follows `nixpkgs`.

## theming

`theme.nix` sits at the repo root and holds two palettes, `blood` (default) and
`copland` — a serial experiments lain reference. a single `variant` string picks
one. both palettes expose the same 26 semantic keys (catppuccin convention) plus
the 16 ansi colours, so any consumer that interpolates `theme.palette.<key>`
rethemes automatically.

the file is imported once in `flake.nix` and threaded to every host through
`specialArgs` as `theme`. `wezterm.lua`, `hyprlock.conf` and `hypr-theme.lua`
(hyprland border colours) are generated from it with `pkgs.writeText`.

## daily workflow

`just` is the entry point. run it with no argument to list the recipes.

```sh
just switch    # rebuild + activate this host (asks for sudo)
just build     # build only, no activation, no sudo
just fmt       # run nixfmt over every .nix file (writes)
just lint      # statix + deadnix
just check     # format check + lint, mirrors what ci should do
just update    # nix flake update, then bump-release on artcraft-launcher and t3code-nightly
just bump-release <file>  # move a pkgs/ package to its latest github release (or nightly)
```

the recipes detect the platform with `uname` and the machine name on their own,
so the same command works on all three hosts. `switch` and `build` use
`justfile_directory()`, so they work from any subdirectory.

order matters: **`fmt` corrects, `check` only verifies.** `check` builds a
derivation that formats a copy of the sources in the nix sandbox and fails on
any diff — it can never write to the repo. so the loop is:

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
# nixos (navi, games). `just switch` adds NIX_REMOTE=daemon, so that builds keep
# the daemon's idle cpu priority. without it, root builds at normal priority.
sudo nixos-rebuild switch --flake .#<hostname>

# darwin (sommei) — activation must run as root
sudo darwin-rebuild switch --flake .#sommei
```

on macos the flake attribute must match `scutil --get LocalHostName`, not the
output of `hostname` — that one can be overwritten by dhcp or mdns.

`nix flake lock` adjusts the lock after editing `inputs` without bumping
anything else; `nix flake update` bumps everything.

### is this host in sync with the repo?

```sh
just build
readlink -f /run/current-system              # running system
readlink -f result                           # what the repo builds
readlink -f /nix/var/nix/profiles/system     # what the next boot starts
```

all three paths identical = the machine is exactly the repo, now and after a
reboot. if a rebuild breaks the boot, pick the previous generation in the
systemd-boot menu.

### development shell

```sh
nix develop
```

gives `nixd` (language server), `nixfmt`, `statix`, `deadnix`, `just`, `sops`
and `age` without installing them system-wide. secret editing is
documented in `docs/secrets.md` (in French). sops-nix is the secrets approach.

## state that nix does not manage

a fresh install brings back the config, not this. redo it by hand:

| what | where | how |
|---|---|---|
| tailscale identity | `/var/lib/tailscale` | `sudo tailscale up` |
| mullvad lan sharing | mullvad settings | `mullvad lan set allow` (otherwise tailscale goes through a derp relay when mullvad is on) |
| windows clock (`games` dual boot) | windows registry | `RealTimeIsUniversal = 1` so both os read the rtc as utc |
| wayle gui tweaks | `~/.config/wayle/runtime.toml` | copy what is worth keeping into `config/wayle/config-<host>.toml` |
| ssh keys | `~/.ssh` | regenerate and add to github |
| sops age host key | `/var/lib/sops-nix/key.txt` | `age-keygen` as root; see `docs/secrets.md` |
| sops age user key | `~/.config/sops/age/keys.txt` | `age-keygen`; back it up off-machine — losing it makes secrets unrecoverable unless a host key remains |
| mumble audio backend (nixos) | `~/.config/Mumble/Mumble/mumble_settings.json` | input/output system = `PulseAudio`, otherwise mumble 1.5 gets SIGKILLed with pipewire >= 1.4 |
| game prefixes | `~/Games`, steam library | reinstall from steam / lutris |
| manual Kopuz.app (`sommei`) | `/Applications/Kopuz.app` | delete it after switching, so Launch Services opens `/Applications/Nix Apps/Kopuz.app` |

## gotchas

nix, hjem, desktop and darwin pitfalls met in this repo: [docs/gotchas.md](docs/gotchas.md).

## system

- network: networkmanager, systemd-resolved, tailscale (shields-up stays on
  for navi; games turns it off, so tailnet ACLs are the gate there; tailscaled
  accepts tailscale0 before the nixos firewall), mullvad (daemon + gui).
  the mac's tailscale app is not configured in this repo
- memory: zram swap (zstd, up to 50 % of ram), no disk swap, no hibernation.
  the kernel is tuned for it (`vm.swappiness` 180, `vm.page-cluster` 0)
- desktop: sddm → hyprland, wezterm, nushell (login shell) + starship, wayle bar,
  hyprlock + hypridle (auto-lock, lock before sleep), hyprpolkitagent
- printing: cups
- nix: weekly garbage collection (older than 7 days), store auto-optimisation,
  builds and gc at idle cpu priority
- locale: `en_US.UTF-8` with french regional settings, timezone `Europe/Paris`
- `sommei`: touch id for sudo, declarative dock / finder / trackpad / keyboard
  repeat / screenshot settings

## resources

what keeps each host light, and why: [docs/resources.md](docs/resources.md).

## known gaps

- **sops-nix is the chosen secrets approach.** it is wired on all three hosts, but no secret is defined yet. age recipients in `.sops.yaml` are still placeholders. workflow: `docs/secrets.md`.
- **`just check` evaluates the hosts but does not build them**: a wrong option
  or a typo fails, a package that fails to compile still passes.
- **theming is only half declarative.** kitty, rofi, spicetify and wayle still
  carry hand-written colour files instead of reading `theme.nix`.
- **git history carries several author names.** the identity itself is declared
  in `config/git/config`, linked by hjem.
- **no disk encryption.** navi is a laptop on plain ext4, games is btrfs without
  luks. encrypting means reformatting: back up, reinstall on luks, then
  `systemd-cryptenroll --tpm2-device=auto` for a passwordless unlock at boot.
- **no declarative backups.** restic is only a package on sommei. a
  `services.restic.backups` job needs a repository and its password as a sops
  secret first.
