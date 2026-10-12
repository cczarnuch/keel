/* Keel: out-of-line copies of winbase.h inline string helpers (built with WINE_NO_INLINE_STRING). */
#define WINE_NO_INLINE_STRING
#include <stdarg.h>
#include <windef.h>
#include <winbase.h>
LPSTR WINAPI lstrcpynA( LPSTR dst, LPCSTR src, INT n )
{ LPSTR d = dst; if (n <= 0) return dst; while (n > 1 && *src) { *d++ = *src++; n--; } *d = 0; return dst; }
INT WINAPI lstrlenW( LPCWSTR str )
{ const WCHAR *s = str; if (!str) return 0; while (*s) s++; return s - str; }
