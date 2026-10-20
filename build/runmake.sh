#!/bin/bash
# Run make with markers. Launch detached so a dropped session can't kill it, e.g.:
#   /usr/bin/python3 -c 'import subprocess,sys; subprocess.Popen(["arch","-x86_64","bash",sys.argv[1]],
#     stdout=open("build.log","w"),stderr=subprocess.STDOUT,start_new_session=True)' build/runmake.sh
. "$(dirname "$0")/env.sh"
cd "$BUILD_DIR"
echo "START $(date)"
if caffeinate -is make -j"$JOBS" "$@"; then echo "MAKE_OK $(date)"; else echo "MAKE_FAIL rc=$? $(date)"; fi
