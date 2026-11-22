# nixos-config

> [!NOTE]
> This GitHub repository is a mirror of a self-hosted [Forgejo](https://forgejo.org) instance and may lag behind. It is a personal configuration tailored to specific hardware and is not intended to work out of the box.

A single Nix flake managing two NixOS machines and one macOS (`nix-darwin`) machine, with native dotfiles symlinked from `config/` via [hjem](https://github.com/feel-co/hjem).

## Hosts

| Host | Hardware | Platform | GPU | Role |
|---|---|---|---|---|
| `navi` | ThinkPad X1 Carbon Gen 12 | NixOS (`x86_64-linux`) | Intel Arc | Laptop |
| `games` | i7-13700KF, ASUS TUF H770-Pro | NixOS (`x86_64-linux`) | NVIDIA RTX 4070 | Desktop, gaming (dual-boot Windows) |
| `sommei` | MacBook Pro M1 Pro | `nix-darwin` (`aarch64-darwin`) | Apple Silicon | Multimedia daily driver |

## Architecture

```
.
├── flake.nix         # Flake inputs, dev shell, and host definitions
├── theme.nix         # Single-source color palettes (ramiel, blood, copland)
├── justfile          # Build, switch, lint, health check, and update tasks
├── hosts/            # Per-machine entry points (navi, games, sommei)
├── modules/
│   ├── shared/       # Nix settings and sops-nix wiring shared across OSes
│   ├── core/         # Base NixOS system: boot, networking, zram, users, locale
│   ├── desktop/      # Hyprland, SDDM, Wayle, audio, fonts, theming, hjem links
│   ├── hardware/     # Intel, NVIDIA, Bluetooth, CoolerControl, SMART alerts
│   └── programs/     # CLI, GUI apps, gaming, Spicetify, Sunshine, Ollama, Godot
├── pkgs/             # Custom packages and scripts outside nixpkgs
├── config/           # Native dotfiles linked into $HOME by hjem
└── docs/             # Operational guides and notes
```

**Design choices:**

- **Opt-in modules** — Each host imports only what it needs. Shared modules set defaults with `lib.mkDefault` so hosts override cleanly without `lib.mkForce`.
- **Symlink-only dotfiles** — `hjem` links plain config files from `config/` directly into place instead of wrapping them in Home Manager modules.
- **Unified theming** — `theme.nix` defines the active palette (`ramiel` by default) and renders templated dotfiles at build time. On NixOS, `matugen` handles dynamic wallpaper colors at runtime for Hyprland, Rofi, Wayle, and Vesktop.

## Stack

- **NixOS (`navi`, `games`)**: SDDM → Hyprland (Lua config), Wayle bar, Rofi, WezTerm, Nushell + Starship, PipeWire, Tailscale + Mullvad, zram swap. `games` adds Steam/Proton-GE, Sunshine (streaming to `sommei`), Spicetify, CoolerControl, and Ollama.
- **macOS (`sommei`)**: `nix-darwin` for system preferences, `nix-homebrew` for GUI casks, Fish + Starship, Kitty, and a Nix-managed Godot 4.5 + Android SDK toolchain.
- **Secrets**: `sops-nix` with per-host `age` keys (wired across all hosts; no secrets committed yet).

## Usage

All common tasks run through `just` and auto-detect the OS and hostname:

```sh
just switch      # Rebuild and activate the current host (uses sudo)
just build       # Build without activating
just fmt         # Format all .nix files (nixfmt)
just check       # CI gate: format check, statix, deadnix, darwin shellcheck, flake eval
just doctor      # Read-only health check on the running host
just update      # Update flake inputs and tracked GitHub release packages
```

Enter the dev shell (`nixd`, `nixfmt`, `statix`, `deadnix`, `just`, `sops`, `age`):

```sh
nix develop
```

## Documentation

- [docs/darwin-bootstrap.md](docs/darwin-bootstrap.md) — Setting up a fresh Mac from factory reset to `just switch`
- [docs/godot.md](docs/godot.md) — Godot 4.5 and Android/Quest 3 export toolchain on `sommei`
- [docs/resources.md](docs/resources.md) — Per-host resource, power, and storage optimizations
- [docs/gotchas.md](docs/gotchas.md) — Nix, `hjem`, desktop, and macOS pitfalls
- [docs/secrets.md](docs/secrets.md) — `sops-nix` and `age` workflow (French)
