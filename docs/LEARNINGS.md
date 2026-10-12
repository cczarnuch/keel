# Learnings: Steam Play on macOS with a Proton-style Steamworks bridge

Hard-won facts from getting Persona 5 Royal (AppID 1687950, D3D11, Denuvo, CRI Mana video) running
through Keel's bridge mode on an Apple Silicon Mac. All numbers were measured on that Mac.

## Steam integration
- **Launch options don't expand `$HOME`.** Steam fails with OS Error 260; write the full path.
- **Mac Steam won't exec a script as the launch target** (OS Error 0). Keel ships `keel-launch`, a tiny compiled launcher (`helpers/keel-launch.c`) that execs `/usr/bin/python3 keel`. Keel therefore runs on the system Python 3.9.
- Mac Steam has no Compatibility menu, so Keel works through Launch Options (`keel-launch waitforexitandrun %command%`). An env prefix (`KEEL_GRAPHICS=dxmt …`) works and beats the per-app conf.
- **Denuvo** allows about 5 activations per 24 h. Each new prefix or Wine/hardware change may cost one. Debug with test programs and dry runs (`KEEL_DRY_RUN=1`), not game launches.

## Runner
- **Native arm64 Wine can't run x64 games.** You need an x86_64 Wine under Rosetta (a game-porting-toolkit-style setup).
- **Cross-compiling x86_64 Wine on arm64:** configure with `--build=aarch64-apple-darwin --host=x86_64-apple-darwin`, `CC='/usr/bin/clang -arch x86_64'`, and `--with-wine-tools` from a native arm64 build. `xcrun`/SDK tools are arm64-only on recent macOS, so don't run configure under `arch -x86_64` expecting x86 tools. Use x86_64 deps (freetype, gnutls…) from GPTK with fixed install names.
- **Fast sync:** CrossOver-based Wine implements it as mach-port **msync** (`WINEMSYNC=1`); `WINEESYNC` alone does nothing there. Without it every wait or event is a wineserver round trip:

  | op | default | msync |
  |----|---------|-------|
  | WaitForSingleObject (signaled) | ~8.5 µs | ~0.13 µs |
  | SetEvent | ~6.8 µs | ~0.07 µs |

- **Incomplete prefixes:** an interrupted `wineboot --init` left `system.reg` without services (RpcSs, nsiproxy…), so networking silently failed. Keel now detects this and runs `wineboot -u`.

## lsteamclient on macOS (Proton `proton_11.0`)
- Mac `steamclient.dylib` (x86_64 + arm64) loads in a third-party x86_64 process under Rosetta, and `CreateInterface`/`ConnectToGlobalUser` work while Mac Steam runs. Same SysV ABI as Linux, so Proton's thunks apply unchanged.
- It lacks `Steam_IsKnownInterface` and `Steam_NotifyMissingInterface`, which must be optional. It lives in `Steam.AppBundle/Steam/Contents/MacOS/`, not the compat client path.
- CrossOver's makedep can't build C++ unixlibs. Build the `.cpp` side by hand with `clang++ -std=c++17` and link it against `ntdll.so` (`build/build-lsc-unix.sh`). This needs `WINE_NO_INLINE_STRING` plus a shim for `lstrcpynA`/`lstrlenW`, and a macOS stub for the VK→keycode function.
- `steam_api64.dll` finds the client through `HKCU\Software\Valve\Steam\ActiveProcess` (pid, `SteamClientDll64`). `helpers/keel_steam.exe` (like Proton's steam.exe) sets this up, stages `steamclient64.dll`, and then runs the game.

## Fibers and the `%gs:0x20` slot (crash + kernel panic)
- On macOS x86_64, `%gs` points at the pthread TSD, not the TEB. Games inline `GetCurrentFiber()` as `mov %gs:0x20` and found libpthread's **QoS value** there (`0x8FF`), then crashed.
- Fix part 1: mirror FiberData into `%gs:0x20` and initialise it to NULL per thread.
- That fix then put a *fiber pointer* into the QoS slot. libsystem sends it as the thread priority in mach messages, so **`configd` crashed** ("_pthread_set_properties_self failed"). Once nsiproxy started talking to it, the Mac **kernel-panicked** (watchdog: no checkins from configd for 180 s).
- Fix part 2: zero `%gs:0x20` on every PE→unix transition and restore it on return (`wine-patches/0005`). When testing anything that touches configd, run a watchdog that times `scutil` calls and kills wineserver if configd stalls.

## Performance
- **`InternetGetConnectedStateExW`** cost ~5.7 ms per call (full adapter and route enumeration through nsiproxy), and P5R called it about every frame (4771 calls in one session). A 2 s cache brings that to ~0.
- **D3DMetal and textures with initial data:** a fresh texture created with data goes through the GPU driver's lossless-compression path *on the CPU*. P5R's video creates textures every frame, so cutscenes slowed down. There's no D3DMetal switch for this; DXMT avoids it:

  | CreateTexture2D + initial data | D3DMetal | DXMT v0.80 |
  |---|---|---|
  | R8 1920×1080 immutable | 22.1 ms | 0.64 ms |
  | RG8 960×540 immutable | 13.4 ms | 0.31 ms |
  | RGBA8 1920×1080 immutable | 103.8 ms | 2.65 ms |
  | RGBA8 1920×1080 default | 104.4 ms | 2.86 ms |
  | RGBA8 1920×1080 dynamic | 1.2 ms | 2.72 ms |

  Keel lets you switch per game: `keel graphics <appid> d3dmetal|dxmt`.
- Turn off heavy `WINEDEBUG` channels for real play. Logs grow quickly (e.g. `fixme:nsi:ipv6_forward_enumerate_all` about 10k lines per session).

## Display
- winemac defaults to scaled points. `HKCU\Software\Wine\Mac Driver\RetinaMode=y` gives native panel pixels; Keel applies it (`KEEL_RETINA`, default 1). Retina mode also changes DPI; `KEEL_DPI` sets `LogPixels` if the UI gets tiny.

## Keel bugs fixed along the way
- DXMT staging picked the **32-bit (i386-windows)** DLLs for 64-bit games; it now prefers x86_64-windows.
- `KEEL_WINE` now forces the runner for every runner setting, and `doctor` reports it along with bridge readiness and per-app graphics.
