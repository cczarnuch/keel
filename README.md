# Keel

Steam Play compatibility tool for the macOS Steam client. Same job as Proton: take a Windows game Steam downloaded and run it on this machine. Keel does that with Wine, and translates Direct3D with DXMT (D3D10/11 to Metal) or with Apple's D3DMetal when Game Porting Toolkit or CrossOver is installed.

Keel is not Valve, not Proton, and not affiliated with Steam.

## Install

1. Unzip.
2. Right-click `Install Keel.command` and choose Open (the first time, macOS will ask).
3. Quit Steam completely and open it again.
4. On a game: Properties → Compatibility → check the force box → **Keel Proton**.

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

Steam calls `keel waitforexitandrun <exe> [args…]` with `STEAM_COMPAT_*` set. Also implemented: `run`, `runinprefix`, `destroyprefix`, `getcompatpath`, `getnativepath`, `setup-steam`, `fetch-dxmt`, `doctor`, `version`.

Prefixes live in `STEAM_COMPAT_DATA_PATH` (Steam's `steamapps/compatdata/<appid>`), in the same shape Proton uses.

## Steamworks

Default mode launches the game executable directly. That is enough for a lot of single-player games and not enough for SteamStub DRM. `KEEL_STEAMWORKS=prefix` starts a Windows Steam client inside a Keel prefix and `-applaunch`es the app id. Anti-cheat (Easy Anti-Cheat, BattlEye, Vanguard) does not run under Wine. Keel does not try to bypass it.

## Logs

`compatdata/<appid>/keel.log`
