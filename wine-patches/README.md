# Wine / lsteamclient patches for Keel's bridge runner

Targets:
- **Wine:** CrossOver 11 source drop (`wine-11.0` based; the `wine/` directory of CodeWeavers' CrossOver 26 sources).
- **Proton:** `ValveSoftware/Proton` branch `proton_11.0`, commit `bc89621`. Only `lsteamclient/` is used.

Apply from the top of the Wine tree with `patch -p1`, in this order. Do step 3 first:

| # | Patch | What it does |
|---|-------|--------------|
| 1 | `0001-winemac-arm64-guards.patch` | arm64-only winemac.drv tweaks (`cocoa_window.m`, `event.c`), guarded by `__x86_64__`. Harmless on x86_64; kept so one tree serves both builds. |
| 2 | `0002-configure-add-lsteamclient.patch` | Adds `dlls/lsteamclient` to `configure.ac`. Re-run `autoreconf`/`tools/make_makefiles` (or edit `configure` the same way). |
| 3 | `0003-lsteamclient-macos.patch` | First copy Proton's `lsteamclient/` to `dlls/lsteamclient/`, then apply. Changes: `Steam_IsKnownInterface`/`Steam_NotifyMissingInterface` become optional (Mac `steamclient.dylib` lacks them); `steamclient.dylib` lookup goes `KEEL_STEAMCLIENT_DYLIB` → `~/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS/` → `$STEAM_COMPAT_CLIENT_INSTALL_PATH`; macOS stub for `manual_convert_nNativeKeyCode`; `Makefile.in` drops the `.cpp` sources so makedep only builds the PE side. |
| 4 | `0004-kernelbase-fiberdata-gs.patch` | Mirrors `TEB->Tib.FiberData` into `%gs:0x20` on fiber create/switch/convert. On macOS x86_64, gs points at the pthread TSD, not the TEB, and games inline `GetCurrentFiber()` as `mov %gs:0x20`. |
| 5 | `0005-ntdll-fiberdata-gs-init-and-qos-swap.patch` | Initialises `%gs:0x20` from FiberData (NULL) at thread start. Zeroes it on every PE→unix transition (syscall/unix-call dispatchers) and restores it on return, including user callbacks. That slot is libpthread's QoS slot: leaving a fiber pointer in it crashed `configd`. |
| 6 | `0006-wininet-connstate-cache.patch` | Caches `InternetGetConnectedStateExW` for 2 s. P5R polls it every frame; each call costs about 5.7 ms through nsiproxy. |

`files/keel_strshim.c` is a C file compiled into `lsteamclient.so`. It holds out-of-line `lstrcpynA`/`lstrlenW`, which are needed because the C++ side builds with `WINE_NO_INLINE_STRING`. `build/build-lsc-unix.sh` copies it in.

Build: see `../build/` and `../docs/RUNNERS.md`.
