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
| keyboard | `us,fr` | `fr` only |
| `mainMod` | `SUPER` | `SUPER` via caps lock (`caps:super`, 60% keyboard) |
| wayle config | `config/wayle/config-navi.toml` | `config/wayle/config-games.toml` |
| extras | power management, `powertop` | nvidia (open kernel module, stable branch), steam + proton-ge, coolercontrol (`nct6775`), spicetify, openrgb (leds off at boot), sunshine (stream the desktop to moonlight on the mac) |

per-host values in `hyprland.lua` are picked by reading `/etc/hostname`. the
wayle file is selected through a custom option, `fyrr.wayle.configFile`,
declared in `modules/desktop/hjem.nix`.

**sommei** runs macos. nix-darwin handles the declarative system config, and
homebrew — itself installed and pinned by nix-homebrew — covers the gui casks
that nix handles poorly on mac. godot 4.5 and the android toolchain for a meta
quest 3 export are nix packages; see [godot on sommei](#godot-on-sommei).
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
├── docs/secrets.md        # sops-nix workflow, in French
├── hosts/
│   ├── navi/{default,hardware}.nix
│   ├── games/{default,hardware}.nix
│   └── sommei/default.nix
├── modules/
│   ├── shared/            # nix settings + sops age key (nixos and darwin)
│   ├── core/              # boot, locale, nix daemon, zram, networking, users (no gui)
│   ├── desktop/           # hyprland, sddm, audio, fonts, cursor, printing, hjem
│   ├── hardware/          # intel, nvidia, bluetooth
│   └── programs/          # cli, apps, office, gaming, spicetify, godot-android (sommei)
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

`modules/programs/godot-android.nix` installs godot 4.5.1 (`pkgs.godot_4_5`,
which nixpkgs provides for `aarch64-darwin`), jdk 17, and an android sdk from
`androidenv.composeAndroidPackages`. on this platform `pkgs.jdk17` is the azul
zulu 17 binary. the android sdk license is accepted with
`androidenv.override { licenseAccepted = true; }` on that package set only.
`nixpkgs.config.android_sdk.accept_license` is not set for the rest of the
system.

godot 4.5.1's `platform/android/java/app/config.gradle` pins ndk
`28.1.13356709`, build-tools `35.0.0` and platform `android-35`. ndk
`23.2.8568313` with build-tools 34 and `android-34` is the godot 4.4 set; a
4.5 gradle export fails if that is all that is installed. platform-tools in
this nixpkgs revision is `37.0.1` (godot asks for >= 35). cmdline-tools is
`22.0`, the arm64 macos build, with `cmdline-tools/latest` linked to it.
cmake is not installed. the 3.10.2 macos package is x86_64-only, and a 4.5
template export does not call it. `includeCmake` defaults to true on darwin,
so the module sets it to false.

store paths change on each rebuild. nix-darwin `environment.etc` keeps two
symlinks. paste them into godot, editor settings → export → android:

| setting | path |
|---|---|
| java sdk path | `/etc/godot/jdk` |
| android sdk path | `/etc/godot/android-sdk` |

the ndk sits under the sdk path:
`/etc/godot/android-sdk/ndk/28.1.13356709`. `adb` is
`/etc/godot/android-sdk/platform-tools/adb` and is also on `PATH`.

`JAVA_HOME`, `ANDROID_HOME` and `ANDROID_SDK_ROOT` are those same directories.
fish, the login shell on sommei, reads `environment.variables` from
`/etc/fish/nixos-env-preinit.fish`. godot itself does not take the export
paths from the environment: the editor settings are the two `/etc/godot`
paths above. nix-darwin already links the bundle into `/Applications/Nix Apps`
(the package names it `GodotMono.app` even without mono).

export templates are not managed. the editor rewrites
`~/Library/Application Support/Godot/export_templates/4.5.1.stable`, same
reason zen's `profiles.ini` is only seeded once. install them from the editor
(manage export templates).

quest 3 is an android device. use an android export preset with arm64 and
deploy with `adb` after developer mode is on. no separate meta sdk is
installed.

on aarch64-darwin, `godot_4_5` crashes with the metal renderer: spirv-cross
and moltenvk collide. launch with `--rendering-driver vulkan`, or set
`rendering/rendering_device/driver.macos` to `vulkan` in the project settings.

checked against the sdk zips this nixpkgs fetches, on aarch64-darwin:

- `adb` and build-tools 35.0.0 are universal (x86_64 and arm64). they run
  natively.
- ndk r28b keeps its host tools in `toolchains/llvm/prebuilt/darwin-x86_64`.
  the directory name is historical; the sampled `llvm-readobj` is universal,
  so the compiler runs natively. rosetta is not required for the ndk.
- cmdline-tools 22.0 is the macos arm64 archive.
- `composeAndroidPackages` also links the obsolete sdk tools 26.1.1 package
  (2017, including `tools/lib/monitor-x86_64`) and wraps those scripts with
  jdk 8. godot 4.5 does not call them.

`just check` evaluates the darwin configuration and does not build it.
godot 4.5.1 is substituted from the binary cache. it is not compiled on the mac.

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
just update    # nix flake update (bumps every input)
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
# nixos (navi, games)
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
  hyprland needs a full logout, `hyprctl reload` does not re-read the lua.
- **hjem links files, not directories**, so it does not clobber things like
  fish's `conf.d/` or `functions/`.
- **never declare a file the app rewrites itself.** the app replaces the symlink
  with a real file and the next rebuild conflicts with it. seen with zen's
  `profiles.ini` (seeded once by an activation script on `sommei`) and wayle's
  `runtime.toml` (left to wayle, only `config.toml` is declared).

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
- **workspace 3 is a fixed chat layout**, not dwindle. `hyprland.lua`
  registers a lua layout (`hl.layout.register`, hyprland >= 0.56) that picks
  the area from the window class: vesktop the full left half, a wezterm
  started with the session (`ws3-term`: fastfetch, then a normal nushell)
  top-right, fsa bottom-right. equibop has no workspace rule and opens
  wherever it wants. open order does not matter, and a closed
  app leaves its area empty. gajim also lands on workspace 3 but floats,
  centred, above the grid. any other tiled window fills a free area; when
  there are more tiled windows than areas, the workspace falls back to a
  plain grid. resizing tiles there does nothing.
- **`pkexec` is not setuid by default** on current nixos
  (`security.polkit.enablePkexecWrapper`). use `sudo`.

**darwin**

- **`homebrew.onActivation.cleanup = "uninstall"`** removes any cask that is not
  in the declared list. brew now prints a deprecation warning for the underlying
  flag.

## system

- network: networkmanager, systemd-resolved, tailscale (shields-up stays on
  for navi; games turns it off, so tailnet ACLs are the gate there; tailscaled
  accepts tailscale0 before the nixos firewall), mullvad (daemon + gui).
  the mac's tailscale app is not configured in this repo
- memory: zram swap (zstd, up to 50 % of ram), no disk swap, no hibernation
- desktop: sddm → hyprland, wezterm, nushell (login shell) + starship, wayle bar,
  hyprlock + hypridle (auto-lock, lock before sleep), hyprpolkitagent
- printing: cups
- nix: weekly garbage collection (older than 7 days), store auto-optimisation
- locale: `en_US.UTF-8` with french regional settings, timezone `Europe/Paris`
- `sommei`: touch id for sudo, declarative dock / finder / trackpad / keyboard
  repeat / screenshot settings

## known gaps

- **sops-nix is the chosen secrets approach.** it is wired on all three hosts, but no secret is defined yet. age recipients in `.sops.yaml` are still placeholders. workflow: `docs/secrets.md`.
- **`just check` evaluates the hosts but does not build them**: a wrong option
  or a typo fails, a package that fails to compile still passes.
- **theming is only half declarative.** kitty, rofi, spicetify and wayle still
  carry hand-written colour files instead of reading `theme.nix`.
- **git history carries several author names.** the identity itself is declared
  in `config/git/config`, linked by hjem.
