/* keel-launch: tiny native launcher for Steam's Launch Options.
 * Finds its own directory and execs /usr/bin/python3 <dir>/keel with all arguments.
 * Build: clang -O2 -o keel-launch helpers/keel-launch.c */
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    char raw[PATH_MAX], real[PATH_MAX], script[PATH_MAX];
    uint32_t size = sizeof(raw);
    if (_NSGetExecutablePath(raw, &size) != 0 || !realpath(raw, real)) {
        fprintf(stderr, "keel-launch: cannot locate myself\n");
        return 127;
    }
    snprintf(script, sizeof(script), "%s/keel", dirname(real));
    char **args = calloc((size_t)argc + 2, sizeof(char *));
    if (!args) return 127;
    args[0] = "/usr/bin/python3";
    args[1] = script;
    for (int i = 1; i < argc; i++) args[i + 1] = argv[i];
    execv(args[0], args);
    perror("keel-launch: execv /usr/bin/python3");
    return 127;
}
