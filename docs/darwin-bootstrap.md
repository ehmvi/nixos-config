# bringing up a new mac

how i go from a factory macbook to a working `just switch`. i checked each step
against the repo, the locked nix-darwin (`ff0e21a`) and nix-homebrew
(`52bc87d`) sources, and the current sommei. i haven't replayed it on a blank
machine, so steps i couldn't check are marked _(unverified)_.

## 1. setup assistant

- **account short name: `user`.** `flake.nix` passes `username = "user"`, and
  `hosts/sommei/default.nix` declares `users.users.user` with `uid = 501`,
  lists it in `users.knownUsers` and makes it `system.primaryUser`. the first
  account the setup assistant creates gets uid 501. with any other name,
  activation aborts because the primary user doesn't exist, and nix-darwin
  would try to create `user` on a uid that is already taken.
- **touch id:** enroll a finger now. sudo uses `pam_tid` once the switch runs.
- **apple id:** nothing in the repo needs it (no `homebrew.masApps`). sign in
  only for icloud and the app store apps i install by hand.
- **name the machine `sommei`** (System Settings > General > Sharing > Local
  hostname, or `sudo scutil --set LocalHostName sommei`). `just switch` picks
  the flake attribute from `scutil --get LocalHostName`.

## 2. prerequisites

```sh
xcode-select --install
```

the command line tools give me `git` to clone the repo. homebrew also expects
them _(unverified on a fresh mac: nix-homebrew doesn't check for them)_.

rosetta isn't needed. `nix-homebrew.enableRosetta = false`, so there is no
intel homebrew prefix in `/usr/local`, and the main binary of every declared
cask is arm64 (checked with `lipo -archs`). if a hand-installed app asks for
it later: `softwareupdate --install-rosetta`.

## 3. install nix

use the lix installer. it's what this mac used (`/nix/receipt.json`), and the
nix-darwin readme of the locked revision recommends it because it ships an
uninstaller (`/nix/nix-installer uninstall`):

```sh
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

it turns on `nix-command` and `flakes` (`enable_flakes: true` in the receipt).
the installer doesn't decide which nix runs afterwards: nix-darwin keeps
`nix.enable` on by default, takes over the daemon and installs `nix.package`
(upstream nix from nixpkgs). that's why `nix --version` here says
`nix (Nix) ...` and not lix.

don't use the determinate installer. it now installs determinate nix with its
own daemon (`determinate-nixd`). nix-darwin aborts with `Determinate detected`
unless `nix.enable = false`, and `modules/shared/nix.nix` needs `nix.enable`
for `nix.settings` and `nix.gc`. the official upstream installer should work
too, but it has no uninstaller _(unverified with this repo)_.

open a new terminal so `nix` is on the path.

## 4. clone

```sh
mkdir -p ~/code
git clone https://github.com/ehmvi/nixos-config ~/code/nixos-config
cd ~/code/nixos-config
```

https, because the ssh keys only arrive in step 7. switch `origin` to the ssh
remote afterwards.

## 5. first activation

```sh
sudo nix run --inputs-from . nix-darwin#darwin-rebuild -- switch --flake .#sommei
```

- `darwin-rebuild` and `just` aren't installed yet, so `nix run` provides it.
- `--inputs-from .` resolves `nix-darwin` to the revision in `flake.lock`. the
  readme's `nix-darwin/master` would take whatever master is today.
- `.#sommei` is explicit. if the setup assistant gave the machine another
  name, `scutil` would point at a config that doesn't exist.
- with an installer that doesn't turn on flakes, add
  `--extra-experimental-features 'nix-command flakes'` after `nix`.

what can stop it:

- **files in `/etc`.** nix-darwin manages `/etc/bashrc`, `/etc/zshrc`,
  `/etc/zshenv`, `/etc/zprofile`, `/etc/shells`, `/etc/nix/nix.conf` and a few
  more. when a file matches a stock macos or installer hash, nix-darwin renames
  it to `<file>.before-nix-darwin` itself. otherwise it aborts with
  `Unexpected files in /etc`. read the file, then
  `sudo mv /etc/<file>{,.before-nix-darwin}` and rerun. `/etc/nix/nix.custom.conf`
  gets the same treatment with its own error.
- **`nix-daemon.sh` in `/etc/profile`** aborts too. remove the `# Nix` block it
  prints.
- **homebrew.** nix-homebrew installs brew into `/opt/homebrew` during
  activation, then nix-darwin runs `brew bundle` for the taps, brews and casks.
  the first run is long. `autoMigrate = true` takes over an existing
  `/opt/homebrew` instead of aborting. casks shipped as `.pkg` (like
  `gstreamer-runtime`) may ask for the password _(unverified)_.
- **the user.** `user` already exists with uid 501, so nix-darwin only sets
  its shell to fish. it needs full disk access only to create or delete
  users, so there should be no prompt here. if one shows up, accept it.

then open a new terminal (fish, with starship). from now on `just switch`
works, as long as `scutil --get LocalHostName` says `sommei`.

## 6. prompts nix can't answer

- **msga** isn't notarized. on first launch: System Settings > Privacy &
  Security > "Open Anyway" (see the cask comment).
- **fsa** copies `BlackHole2ch.driver` into `/Library/Audio/Plug-Ins/HAL` and
  restarts coreaudiod. it's a hal plug-in, not a system extension, so there is
  nothing to approve. the app asks for the microphone the first time it runs
  _(unverified)_.
- **mullvad vpn** asks to add a vpn configuration on first connect
  _(unverified)_.
- **full disk access** for the terminal only if `darwin-rebuild` asks for it.
- **yabai scripting addition (once per mac):** boot into Recovery Mode (hold
  power button on Apple Silicon), open Terminal and run
  `csrutil enable --without fs --without debug --without nvram`. reboot into
  macOS, run `sudo nvram boot-args=-arm64e_preview_abi`, and reboot again.
  `services.yabai.enableScriptingAddition = true` handles the `yabai-sa`
  daemon and `/etc/sudoers.d/yabai` automatically afterwards.
- **accessibility permissions:** grant Accessibility to `yabai` and `skhd`
  (System Settings > Privacy & Security > Accessibility). if a `yabai` or
  `skhd` nixpkgs bump changes the store path, re-enable it there and restart
  the agent (`launchctl kickstart -k gui/$(id -u)/org.nixos.yabai`).
- **touch id for sudo** needs the finger enrolled in step 1.
  `reattach` makes it work inside tmux and cmux.
- the per-app theme settings in the readme ("settings to set once in each
  app"), the zed theme for example.

## adding a second mac instead

if the new mac sits beside sommei instead of replacing it:

1. `cp hosts/sommei/default.nix hosts/<name>/default.nix`. the file reads
   `username` from `specialArgs`, so the user doesn't need editing.
2. in `flake.nix`, copy the `darwinConfigurations.sommei = mkHost { ... }`
   block to `darwinConfigurations.<name>`, pointing at
   `./hosts/<name>/default.nix` and keeping `nix-homebrew` and `fsa`.
   `username` is the short name from the setup assistant. uid 501 still
   holds, because it's the first account there too.
3. add the host to the `eval` recipe in the `justfile`, so `just check`
   evaluates it.
4. `git add hosts/<name>` (flakes only see tracked files), name the machine
   `<name>`, and run step 5 with `.#<name>`.
5. give it its own recipient in `.sops.yaml` once secrets exist.

## 7. state that isn't in the repo

carry these over by hand, from the old mac or a backup:

| what | where | note |
|---|---|---|
| ssh keys | `~/.ssh/id_ed25519`, `~/.ssh/id_ed25519_signing` (+ `.pub`) | `config/git/config` turns on `commit.gpgsign` and `tag.gpgsign` with the signing key: without it every commit fails |
| ssh config | `~/.ssh/config` | |
| `~/.gitconfig` | home | sits beside the hjem-managed `~/.config/git/config`. git reads it last, so its `user.name`, `user.email`, `credential.helper`, `core.editor` and lfs filters win. fold what matters into `config/git/config`, or copy it |
| sops age keys | `/var/lib/sops-nix/key.txt`, `~/.config/sops/age/keys.txt` | neither exists yet: `.sops.yaml` still has placeholders. once they exist, carry both. see [secrets.md](secrets.md) (in french) |
| neovim | `~/.config/nvim` | lazyvim, not managed by hjem |
| zed | `~/.config/zed/settings.json` | the theme is in the repo, the settings aren't |
| karabiner | `~/.config/karabiner` | the app is installed by hand too, and needs its driver approved |
| cmux | `~/.config/cmux` | `cmux.json`, `settings.json` |
| raycast | `~/.config/raycast`, `~/Library/Application Support/com.raycast.macos` | raycast's own settings export is the clean way _(unverified)_ |
| cli tools | `~/.local/bin`, `~/.npm-global/bin` | claude, uv/uvx, codex and a few more, installed imperatively. `nodejs_22` comes from nix, the global npm prefix doesn't |
| hand-installed apps | `/Applications` | adobe creative cloud, ableton live, davinci resolve, cinema 4d, raycast, karabiner, tailscale, signal, obs, zed, ... with their licences |
| app sign-ins | per app | bitwarden, brave, obsidian vault, discord clients, t3 code (`~/.t3/userdata`), mullvad, tailscale |
| backups | none | restic is installed, but no `services.restic.backups` job exists. copy data off the old mac before wiping it |

installing one of those apps with `brew install --cask` by hand doesn't last:
`onActivation.cleanup = "uninstall"` removes it at the next switch. declare it
in `homebrew.casks` instead.

## 8. check list

```sh
just check                                     # format, lint, eval
just build                                     # = darwin-rebuild build --flake .#sommei
readlink -f /run/current-system; readlink -f result   # same path: the mac matches the repo
scutil --get LocalHostName                     # sommei
dscl . -read /Users/user UserShell             # /run/current-system/sw/bin/fish
sudo -k; sudo true                             # asks for touch id
ls ~/Library/Application\ Support/zen/profiles.ini \
   ~/Library/Application\ Support/zen/Profiles/default/user.js   # zen profile seeded
brew list --cask                               # the casks from hosts/sommei/default.nix
```

then a signed commit in any repo, and `BlackHole 2ch` in the sound input list.
