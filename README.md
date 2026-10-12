# Keel

Steam Play compatibility tool for the macOS Steam client. Same job as Proton: take a Windows game Steam downloaded and run it on this machine. Keel does that with Wine, and translates Direct3D with DXMT (D3D10/11 to Metal) or with Apple's D3DMetal when Game Porting Toolkit or CrossOver is installed.

Keel is not Valve, not Proton, and not affiliated with Steam.

## Install

1. Unzip.
2. Right-click `Install Keel.command` and choose Open (the first time, macOS will ask).
3. Quit Steam completely and open it again.
4. On a game: Properties → Launch Options. Paste the line the installer copied. It looks like this, with your own home folder instead of `YOURNAME`:

```
"/Users/YOURNAME/Library/Application Support/Steam/compatibilitytools.d/keel-proton/keel-launch" waitforexitandrun %command%
```

`keel-launch` is a small compiled program (built by the installer from `helpers/keel-launch.c`) that runs `/usr/bin/python3 keel`. Do not put `$HOME`, `~`, or a path to a script such as `keel` in that box: Steam does not expand `$HOME`, and it will not start a script. Both mistakes show up as **Failed to start process: OS Error 260** (or OS Error 0).

The installer copies a finished line, with your path filled in, to the clipboard.

Mac Steam has no Compatibility section. Valve ships the Steam Play code and leaves the checkbox off. Dropping a tool in `compatibilitytools.d` does not create the menu. Keel does not inject into Steam to force it on. Launch Options is the path that still works after a Steam update.

If a Windows-only game has no Install button, run the installer again and enable the Windows depot switch. That writes one line Valve already documents for developers, `@sSteamCmdForcePlatformType windows`, into `steam_dev.cfg`. While that line is there, Steam may prefer Windows depots even for games that have a Mac build. Remove it from the same file to undo.

## What has to already be on the Mac

Keel does not ship Wine. It uses the first runner it finds:

1. `KEEL_WINE`, if you set it
2. CrossOver
3. Game Porting Toolkit (`wine64` from the toolkit)
4. Whisky
5. Homebrew `wine64` / `wine`

DirectX 11 needs [DXMT](https://github.com/3Shain/dxmt). The installer can download a release into `~/Library/Application Support/Keel/dxmt`. DirectX 12 needs D3DMetal, which ships inside Game Porting Toolkit and recent CrossOver. Keel cannot redistribute either.

## Verbs

Launch Options calls `keel waitforexitandrun <exe> [args…]`. Steam on Mac does not set `STEAM_COMPAT_*`, so Keel fills those in from `SteamAppId`. Also implemented: `run`, `runinprefix`, `destroyprefix`, `getcompatpath`, `getnativepath`, `setup-steam`, `fetch-dxmt`, `doctor`, `version`.

Prefixes live in `STEAM_COMPAT_DATA_PATH` (Steam's `steamapps/compatdata/<appid>`), in the same shape Proton uses.

## Steamworks

Default mode launches the game executable directly. That is enough for a lot of single-player games and not enough for SteamStub DRM. `KEEL_STEAMWORKS=bridge` (below) talks to Mac Steam directly. `KEEL_STEAMWORKS=prefix` starts a Windows Steam client inside a Keel prefix and `-applaunch`es the app id. Anti-cheat (Easy Anti-Cheat, BattlEye, Vanguard) does not run under Wine. Keel does not try to bypass it.

### Bridge mode (`KEEL_STEAMWORKS=bridge`)

This works like Proton. The game's `steam_api64.dll` loads a Wine build of Proton's `lsteamclient` (staged as `C:\Program Files (x86)\Steam\steamclient64.dll`). That library forwards every Steamworks call to the Mac Steam client's own `steamclient.dylib`, so achievements, cloud saves, and DRM checks go through the Steam you are already signed into. No Windows Steam is needed.

Requirements:

- An x86_64 Wine 11 runner that ships `lib/wine/x86_64-windows/lsteamclient.dll` and `lib/wine/x86_64-unix/lsteamclient.so`. Point `KEEL_WINE` at its `bin/wine`.
- The runner's x86_64 dependency dylibs. They are found through `KEEL_DYLD_PATH` (colon-separated, default `~/opt/cxdeps-x86/lib`).
- Mac Steam running. `KEEL_STEAMCLIENT_DYLIB` overrides the path to `steamclient.dylib`.

Keel copies `helpers/keel_steam.exe` into the prefix and launches the game through it. Like Proton's `steam.exe`, it registers itself as the active Steam process (`HKCU\Software\Valve\Steam\ActiveProcess`) and then waits for the game. `keel doctor` reports whether the bridge is ready.

Per-game settings live in `~/Library/Application Support/Keel/apps/<appid>.conf`, for example:

```
KEEL_WINE=/Users/YOU/opt/wine-cx11-x86/bin/wine
KEEL_STEAMWORKS=bridge
KEEL_GRAPHICS=d3dmetal
```

## Display resolution (`KEEL_RETINA`)

Wine's Mac driver reports scaled points by default (e.g. 1512x982 on a 14" MacBook Pro), so games pick a low resolution. Keel sets `HKCU\Software\Wine\Mac Driver\RetinaMode=y` in every prefix it launches, so games see native pixels (3024x1964 on that panel). Set `KEEL_RETINA=0` to turn it back off, or leave it empty to have Keel not touch it. Retina mode also makes Wine's own dialogs smaller. `KEEL_DPI` sets Wine's `LogPixels` (96 = 100%, e.g. 175 for ~1080p-sized UI on a 3024x1964 panel) in both `HKCU\Control Panel\Desktop` and `HKLM\...\Hardware Profiles\Current\Software\Fonts`; leave it empty to not touch it. It affects Wine dialogs and DPI-aware apps; a game's own 3D/UI scale follows its render resolution. Games that remember a resolution (P5R's `ScreenSetting.xml`) keep the old one until you change it in the game's settings.

## Prefix repair

If a prefix was created by a `wineboot` that got interrupted (no services such as RpcSs or nsiproxy registered), Keel runs `wineboot -u` before launching. Symptoms of such a prefix: `err:ole:start_rpcss Failed to open RpcSs service`, online features silently not working.

## Fast sync

`KEEL_ESYNC=1` (default) sets both `WINEESYNC=1` and `WINEMSYNC=1`. CrossOver-based runners use msync (mach semaphores); in a microbenchmark it cut `WaitForSingleObject(0)` from ~8.5 us to ~0.13 us and `SetEvent` from ~6.8 us to ~0.07 us. Set `WINEMSYNC=0` in a per-app conf to turn it off.

## Logs

Wine's own output goes to `$STEAM_COMPAT_DATA_PATH/wine.log` (overwritten on each launch; `KEEL_WINE_LOG=0` disables it). For more detail, set `WINEDEBUG` in the per-app conf, e.g. `WINEDEBUG=err+all,warn+winhttp,warn+secur32,warn+winsock`.

`compatdata/<appid>/keel.log`

## Switching graphics backends (D3DMetal ↔ DXMT)

`KEEL_GRAPHICS` is the single switch: `d3dmetal`, `dxmt`, `dxvk`, `wined3d` or `auto`.
With a Wine 11 bridge runner, D3DMetal and DXMT live in separate runner variants. Name them in the
per-app conf (`~/Library/Application Support/Keel/apps/<appid>.conf`) and Keel picks the matching one:

```
KEEL_WINE_D3DMETAL=/Users/you/opt/wine-cx11-x86/bin/wine
KEEL_WINE_DXMT=/Users/you/opt/wine-cx11-x86-dxmt/bin/wine
KEEL_GRAPHICS=d3dmetal
```

If no variant is set for the chosen backend, `KEEL_WINE` is used. With a DXMT runner Keel uses its
builtin `d3d11/dxgi/d3d10core/winemetal` and copies `winemetal.dll` into the prefix's `system32`
(the old native-DLL staging from `keel fetch-dxmt` is only used when there's no DXMT runner).
`keel.log` records the chosen runner and backend.

Switch either way:

- edit the `KEEL_GRAPHICS=` line in the conf, or
- `python3 ~/"Library/Application Support/Steam/compatibilitytools.d/keel-proton/keel" graphics 1687950 dxmt`
  (no backend argument prints the current one; the conf is backed up once as `.conf.bak`).

For a one-off launch, put it in Steam's Launch Options. The environment beats the conf:

```
KEEL_GRAPHICS=dxmt "/Users/you/Library/Application Support/Steam/compatibilitytools.d/keel-proton/keel-launch" waitforexitandrun %command%
```

`KEEL_DRY_RUN=1` logs the runner, overrides and command, then exits without touching the prefix or starting Wine.
`keel doctor` lists per-app graphics.
