#!/bin/bash
# Configure an x86_64 Wine 11 build on an arm64 Mac (cross: --build aarch64, --host x86_64).
set -e
. "$(dirname "$0")/env.sh"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR" && rm -f config.cache
CC='/usr/bin/clang -arch x86_64' CXX='/usr/bin/clang++ -arch x86_64' \
CFLAGS="-O2 -I$DEPS/include" CPPFLAGS="-I$DEPS/include" \
LDFLAGS="-L$DEPS/lib -Wl,-rpath,$DEPS/lib" PKG_CONFIG_LIBDIR=/nonexistent \
FREETYPE_CFLAGS="-I$DEPS/include/freetype2" FREETYPE_LIBS="-L$DEPS/lib -lfreetype" \
GNUTLS_CFLAGS="-I$DEPS/include" GNUTLS_LIBS="-L$DEPS/lib -lgnutls" \
"$WINE_SRC/configure" --build=aarch64-apple-darwin --host=x86_64-apple-darwin \
  --with-wine-tools="$NATIVE_TOOLS" --prefix="$PREFIX" --disable-tests \
  --enable-archs=x86_64,i386 --with-mingw="$LLVM_MINGW/bin/clang" \
  --without-x --without-wayland --with-coreaudio --with-cups --with-freetype \
  --without-gettext --without-gettextpo --with-gnutls --without-gphoto --without-gstreamer \
  --without-alsa --without-capi --without-dbus --without-inotify --without-krb5 --without-netapi \
  --without-oss --without-pulse --without-sane --without-udev --without-usb --without-v4l2 \
  --without-sdl --with-pthread --with-unwind --with-vulkan --disable-option-checking
