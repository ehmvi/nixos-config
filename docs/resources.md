# resources

hardware is expensive, so the config stays light without giving up an app:

| host | what keeps it light |
|---|---|
| all nixos | no app started at login, zram tuning, 256 mb journal, nix at idle cpu priority, no speech-dispatcher service or voices (734 mb on `games`), no wait for the network at boot, wayle cpu module polled every 5 s, no cursor fade in wezterm, no shell spawned by the hyprlock clock |
| `games` | btrfs `compress=zstd:1` + `noatime`, coolercontrol polled every 3 s, ollama unloads its model after 2 min, no split lock penalty in games |
| `sommei` | no sdk tools or jdk 8, zen saves its session every 60 s |
| `navi` | gpu video decoding in mpv, `noatime` |

btrfs only compresses what gets written after the switch, so the store shrinks
as updates replace it. rewriting it all at once would cost as many ssd writes as
the store is big, for a gain that comes anyway.
