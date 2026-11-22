# resources

hardware is expensive, so the config stays light without giving up an app:

| host | what keeps it light |
|---|---|
| all nixos | no app started at login, `/tmp` on tmpfs, zram tuning + `systemd-oomd` on user slices, fixed dirty writeback caps (64/256 MiB) + `vfs_cache_pressure = 50`, BBR + `fq`, weekly idle `nix.optimise` instead of inline deduplication, 256 mb journal, nix builds and gc at idle cpu priority, no speech-dispatcher service or voices (734 mb on `games`), no wait for the network at boot, hyprland 2-pass blur + fullscreen-only VRR + game-only direct scanout, pipewire realtime group, wayle cpu module polled every 5 s, steady cursor in wezterm, no shell spawned by the hyprlock clock (date and battery: one `/bin/sh` per minute), clipboard history from a single `wl-paste --watch cliphist store` (no primary selection watcher, no `wl-clip-persist`) |
| `games` | btrfs `compress=zstd:1` + `noatime`, rtx 4070 capped at 170 w with VRAM preserved in `/tmp` tmpfs across suspend, coolercontrol polled every 3 s, gamemode + `ananicy-cpp`, ollama unloads after 2 min with flash attention + `q8_0` KV cache, no split lock penalty in games, `smartd` Wayland alerts + scheduled self-tests |
| `sommei` | no sdk tools or jdk 8, zen saves its session every 60 s (60 fps cap), kitty stops cursor blinking after 15 s idle, snappier dock/window animations, aldente battery cap |
| `navi` | gpu video decoding (`intel-media-driver` + `vpl-gpu-rt`), `noatime` + `commit=60`, thinkpad battery charge capped at 75–80 %, `smartd` Wayland alerts + scheduled self-tests |

btrfs only compresses what gets written after the switch, so the store shrinks
as updates replace it. rewriting it all at once would cost as many ssd writes as
the store is big, for a gain that comes anyway.
