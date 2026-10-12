# Shared settings for the x86_64 Wine 11 cross-build. Override any of these in the environment.
: "${KEEL_CX_SRC:=$HOME/Downloads/sources}"     # unpacked CrossOver sources (keel fetch-crossover-src)
: "${WINE_SRC:=$KEEL_CX_SRC/wine}"              # CrossOver 26 (Wine 11) wine tree, patched (see wine-patches/)
: "${PROTON_SRC:=${KEEL_PROTON_SRC:-$HOME/src/proton}}"             # Proton checkout at proton_11.0 / bc89621
: "${BUILD_DIR:=$HOME/opt/wine-cx-x86-build}"   # out-of-tree x86_64 build dir
: "${NATIVE_TOOLS:=$HOME/opt/wine-cx-build}"    # an arm64 build of the same tree (provides wine tools)
: "${PREFIX:=$HOME/opt/wine-cx11-x86}"          # install prefix (the Keel runner)
: "${DEPS:=$HOME/opt/cxdeps-x86}"               # x86_64 freetype/gnutls/... (lib/, include/)
: "${LLVM_MINGW:=$HOME/opt/llvm-mingw}"         # llvm-mingw with x86_64 + i686 targets
: "${BISON_DIR:=$HOME/opt/bison}"               # bison >= 3 (Xcode's is too old)
: "${JOBS:=10}"
export PATH="$BISON_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$LLVM_MINGW/bin"
if [ ! -f "$WINE_SRC/configure.ac" ] || [ ! -d "$WINE_SRC/dlls/lsteamclient" ]; then
  echo "error: no patched Wine tree at $WINE_SRC. Run: keel fetch-crossover-src (or set WINE_SRC)" >&2
  exit 1
fi
