# Shared settings for the x86_64 Wine 11 cross-build. Override any of these in the environment.
: "${WINE_SRC:=$HOME/src/wine-cx11}"            # CrossOver 11 wine sources, patched (see wine-patches/)
: "${PROTON_SRC:=$HOME/src/proton}"             # Proton checkout at proton_11.0 / bc89621
: "${BUILD_DIR:=$HOME/opt/wine-cx-x86-build}"   # out-of-tree x86_64 build dir
: "${NATIVE_TOOLS:=$HOME/opt/wine-cx-build}"    # an arm64 build of the same tree (provides wine tools)
: "${PREFIX:=$HOME/opt/wine-cx11-x86}"          # install prefix (the Keel runner)
: "${DEPS:=$HOME/opt/cxdeps-x86}"               # x86_64 freetype/gnutls/... (lib/, include/)
: "${LLVM_MINGW:=$HOME/opt/llvm-mingw}"         # llvm-mingw with x86_64 + i686 targets
: "${BISON_DIR:=$HOME/opt/bison}"               # bison >= 3 (Xcode's is too old)
: "${JOBS:=10}"
export PATH="$BISON_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$LLVM_MINGW/bin"
