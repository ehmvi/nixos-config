# godot on sommei

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
- `composeAndroidPackages` links the obsolete sdk tools 26.1.1 package by
  default (2017, wrapped with jdk 8). godot 4.5 does not call them, so the
  module sets `toolsVersion = null` to keep both out of the closure.

`just check` evaluates the darwin configuration and does not build it.
godot 4.5.1 is substituted from the binary cache. it is not compiled on the mac.
