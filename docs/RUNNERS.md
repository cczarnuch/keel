# Building the bridge runner (x86_64 Wine 11 + lsteamclient + D3DMetal/DXMT)

All paths below are defaults from `build/env.sh`; override them via environment variables.

## 0. Prerequisites
- An arm64 build of the same CrossOver tree in `$NATIVE_TOOLS`. Only its `tools/` (winebuild, widl, makedep…) are used; macOS's `xcrun` is arm64-only, so tools must be native.
- `llvm-mingw` with `x86_64-w64-mingw32` and `i686-w64-mingw32` targets; bison ≥ 3.
- x86_64 dependencies in `$DEPS/{lib,include}`. The x86_64 `libfreetype.6.dylib`, `libgnutls.30.dylib` (and nettle, hogweed, gmp, idn2, unistring, tasn1, p11-kit) from Apple's Game Porting Toolkit work. Give each an absolute install name (`install_name_tool -id "$DEPS/lib/<name>" …`) and re-sign it ad hoc (`codesign -f -s -`). Otherwise configure records a broken `SONAME_*`.
- Use `/usr/bin/clang -arch x86_64`. llvm-mingw's clang must not come first on PATH, or `ld: library 'System' not found`.

## 1. Wine
1. Get the sources and apply `wine-patches/`: `keel fetch-crossover-src [version]` (default 26.3.0, the Wine 11 based CrossOver release). It downloads `https://media.codeweavers.com/pub/crossover/source/crossover-sources-<version>.tar.gz` (resumable) into `~/Library/Caches/Keel` (`KEEL_CACHE_DIR`), checks it with `tar -tzf` and prints its sha256 (CodeWeavers publishes none), unpacks it to `$KEEL_CX_SRC` (default `~/Downloads/sources`; the Wine tree is `wine/`), then applies 0001–0006 with `patch -p1`, skipping ones already applied. For 0003 it copies `lsteamclient/` from `$KEEL_PROTON_SRC` (default `~/src/proton`, Proton `proton_11.0` @ `bc89621`) first. Re-running is safe. `KEEL_DRY_RUN=1` only prints the plan. To do it by hand, see `wine-patches/README.md`.
2. `build/reconf.sh`, then run `build/runmake.sh` detached (see header comment), then `make install`.
3. `make install` may skip `bin/wine`: `ln -s ../lib/wine/x86_64-unix/wine "$PREFIX/bin/wine"`.
4. `build/build-lsc-unix.sh`, plus `make dlls/lsteamclient/x86_64-windows/lsteamclient.dll`. Copy `lsteamclient.dll` → `$PREFIX/lib/wine/x86_64-windows/` and `lsteamclient.so` → `$PREFIX/lib/wine/x86_64-unix/`.
5. Runtime needs `DYLD_FALLBACK_LIBRARY_PATH=$DEPS/lib:/usr/local/lib:/usr/lib`. Keel sets this from `KEEL_DYLD_PATH`.

## 2. D3DMetal variant (default runner)
Copy (don't move) from GPTK's Wine (`…/lib/wine` of the Game Porting Toolkit bundle) into `$PREFIX`:
- `lib/wine/x86_64-windows/{d3d10,d3d11,d3d12,dxgi,atidxx64,nvngx,nvapi64}.dll`. Back up the Wine 11 originals as `*.wine11.bak`.
- the matching `lib/wine/x86_64-unix/*.so`
- `lib/external/D3DMetal.framework` and `lib/external/libd3dshared.dylib`

Keel uses them with `WINEDLLOVERRIDES=d3d11,dxgi,d3d12,d3d10=b`. Keep a manifest of copied files so the change can be undone.

## 3. DXMT variant
Clone the runner with APFS copy-on-write (it costs almost no disk): `cp -cR "$PREFIX" "$PREFIX-dxmt"`. Then copy DXMT's builtin release (`dxmt-vX-builtin.tar.gz`, tested v0.80) over it:
- `x86_64-windows/{d3d11,dxgi,d3d10core,winemetal}.dll` → `$PREFIX-dxmt/lib/wine/x86_64-windows/`
- `x86_64-unix/winemetal.so` → `$PREFIX-dxmt/lib/wine/x86_64-unix/`

Point `KEEL_WINE_DXMT` at `$PREFIX-dxmt/bin/wine`. Keel uses `d3d11,dxgi,d3d10core,winemetal=b` and copies `winemetal.dll` into the prefix's `system32`; without that placeholder Wine reports `winemetal.dll not found`.
Builtin-signature DLLs dropped into `system32` with an `=n` override do **not** load; use the runner-builtin route.
