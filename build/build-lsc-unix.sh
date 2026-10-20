#!/bin/bash
# Build lsteamclient.so (C++ unix side) by hand: CrossOver's makedep doesn't handle C++ unixlibs.
# Run after the main build (needs dlls/ntdll/ntdll.so and generated include/). The PE side
# (lsteamclient.dll) comes from `make dlls/lsteamclient/x86_64-windows/lsteamclient.dll`.
set -e
. "$(dirname "$0")/env.sh"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BUILD_DIR"
L="$WINE_SRC/dlls/lsteamclient"; O=dlls/lsteamclient/unix; mkdir -p "$O"
cp "$HERE/wine-patches/files/keel_strshim.c" "$O/"
(cd "$L" && ls *.cpp) > lsc-unix-sources.txt
FLAGS=(-arch x86_64 -O2 -g -I"$O" -I"$L" -I"$PWD/include" -I"$WINE_SRC/include" -D__WINESRC__
       -DWINE_NO_INLINE_STRING -DNOMINMAX -DWINE_UNIX_LIB -DSTEAM_API_EXPORTS -fPIC
       -fvisibility=hidden -fno-strict-aliasing -fasynchronous-unwind-tables -fcf-protection=none
       -fno-stack-protector -w)
export O L; export FLAGS_STR="${FLAGS[*]}"
echo "START $(date)"
caffeinate -is xargs -P"$JOBS" -I{} sh -c '/usr/bin/clang++ -std=c++17 -Dprivate=public -Dprotected=public $FLAGS_STR -c -o "$O/$(basename {} .cpp).o" "$L/{}" || echo "COMPILE_FAIL {}"' < lsc-unix-sources.txt
/usr/bin/clang $FLAGS_STR -c -o "$O/keel_strshim.o" "$O/keel_strshim.c"
/usr/bin/clang++ -arch x86_64 -o dlls/lsteamclient/lsteamclient.so -dynamiclib \
  -install_name @rpath/lsteamclient.so -Wl,-rpath,@loader_path/ "$O"/*.o dlls/ntdll/ntdll.so -lc++ \
  && echo MAKE_OK || echo MAKE_FAIL
