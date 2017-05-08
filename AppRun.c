/**************************************************************************

Copyright (c) 2004-16 Simon Peter
Portions Copyright (c) 2010 RazZziel

All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

**************************************************************************/

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>
#include <dirent.h>
#include <string.h>
#include <sys/stat.h>
#include <sched.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <errno.h>

#define die(...)                                \
    do {                                        \
        fprintf(stderr, "Error: " __VA_ARGS__);   \
        exit(1);                              \
    } while (0);

#define PATH_MAX 4096

#define LINE_SIZE 255

#define err_exit(format, ...) { fprintf(stderr, format ": %s\n", ##__VA_ARGS__, strerror(errno)); exit(EXIT_FAILURE); }

int filter (const struct dirent *dir) {
    char *p = (char*) &dir->d_name;
    p = strrchr(p, '.');
    return p && !strcmp(p, ".desktop");
}

static void update_map(char *mapping, char *map_file) {
    int fd;

    fd = open(map_file, O_WRONLY);
    if (fd < 0) {
        err_exit("map open");
    }

    int map_len = strlen(mapping);
    if (write(fd, mapping, map_len) != map_len) {
        err_exit("map write");
    }

    close(fd);
}

static void add_path(const char* name, const char* rootdir) {
    char path_buf[PATH_MAX];
    snprintf(path_buf, sizeof(path_buf), "/%s", name);

    struct stat statbuf;
    if (stat(path_buf, &statbuf) < 0) {
        fprintf(stderr, "Cannot stat %s: %s\n", path_buf, strerror(errno));
        return;
    }

    char path_buf2[PATH_MAX];
    snprintf(path_buf2, sizeof(path_buf2), "%s/%s", rootdir, name);

    mkdir(path_buf2, statbuf.st_mode & ~S_IFMT);
    if (mount(path_buf, path_buf2, "none", MS_BIND | MS_REC, NULL) < 0) {
      fprintf(stderr, "Cannot bind mount %s to %s: %s\n", path_buf, path_buf2, strerror(errno));
    }
}

#define SAVE_ENV_VAR(x) char *x = getenv(#x)
#define LOAD_ENV_VAR(x) setenv(#x, x, 1)

int main(int argc, char *argv[]) {
    char *appdir = dirname(realpath("/proc/self/exe", NULL));
    if (!appdir)
        die("Could not access /proc/self/exe\n");

    char *tmpdir = getenv("TMPDIR");
    if (!tmpdir) {
        tmpdir = "/tmp";
    }

    char template[PATH_MAX];
    int needed = snprintf(template, PATH_MAX, "%s/nixXXXXXX", tmpdir);
    if (needed < 0) {
        err_exit("TMPDIR too long: '%s'", tmpdir);
    }

    char *rootdir = mkdtemp(template);
    if (!rootdir) {
        err_exit("mkdtemp(%s)", template);
    }

    int ret;

    struct dirent **namelist;

    ret = scandir(appdir, &namelist, filter, NULL);

    if (ret == 0) {
        die("No .desktop files found\n");
    } else if(ret == -1) {
        die("Could not scan directory %s\n", appdir);
    }

    /* Extract executable from .desktop file */

    FILE *f;
    char *desktop_file = malloc(LINE_SIZE);
    snprintf(desktop_file, LINE_SIZE-1, "%s/%s", appdir, namelist[0]->d_name);
    f = fopen(desktop_file, "r");

    char *line = malloc(LINE_SIZE);
    size_t n = LINE_SIZE;
    int found = 0;

    while (getline(&line, &n, f) != -1)
    {
        if (!strncmp(line,"Exec=",5))
        {
            char *p = line+5;
            while (*++p && *p != ' ' &&  *p != '%'  &&  *p != '\n');
            *p = 0;
            found = 1;
            break;
        }
    }

    fclose(f);

    if (!found)
      die("Executable not found, make sure there is a line starting with 'Exec='\n");

    /* Execution */
    char *executable = basename(line+5);

    char full_exec[PATH_MAX];
    snprintf(full_exec, sizeof(full_exec), "/usr/bin/%s", executable);

    // get uid, gid before going to new namespace
    uid_t uid = getuid();
    gid_t gid = getgid();

    // "unshare" into new namespace
    if (unshare(CLONE_NEWNS | CLONE_NEWUSER) < 0) {
        err_exit("unshare()");
    }

    // add necessary system stuff to rootdir namespace
    add_path("dev", rootdir);
    add_path("proc", rootdir);
    add_path("sys", rootdir);
    add_path("run", rootdir);
    add_path("etc", rootdir);

    char path_buf[PATH_MAX];
    snprintf(path_buf, sizeof(path_buf), "%s/tmp", rootdir);
    mkdir(path_buf, ~0);
    snprintf(path_buf, sizeof(path_buf), "%s/var", rootdir);
    mkdir(path_buf, ~0);

    // make sure nixdir exists
    struct stat statbuf2;
    if (stat(appdir, &statbuf2) < 0) {
        err_exit("stat(%s)", appdir);
    }

    char nixdir[PATH_MAX];
    snprintf(nixdir, sizeof(nixdir), "%s/nix", appdir);
    snprintf(path_buf, sizeof(path_buf), "%s/nix", rootdir);
    mkdir(path_buf, statbuf2.st_mode & ~S_IFMT);
    if (mount(nixdir, path_buf, "none", MS_BIND | MS_REC, NULL) < 0) {
        err_exit("mount(%s, %s)", nixdir, path_buf);
    }

    char usrdir[PATH_MAX];
    snprintf(usrdir, sizeof(usrdir), "%s/usr", appdir);
    snprintf(path_buf, sizeof(path_buf), "%s/usr", rootdir);
    mkdir(path_buf, statbuf2.st_mode & ~S_IFMT);
    if (mount(usrdir, path_buf, "none", MS_BIND | MS_REC, NULL) < 0) {
        err_exit("mount(%s, %s)", usrdir, path_buf);
    }

    // fixes issue #1 where writing to /proc/self/gid_map fails
    // see user_namespaces(7) for more documentation
    int fd_setgroups = open("/proc/self/setgroups", O_WRONLY);
    if (fd_setgroups > 0) {
        write(fd_setgroups, "deny", 4);
    }

    // map the original uid/gid in the new ns
    char map_buf[1024];
    snprintf(map_buf, sizeof(map_buf), "%d %d 1", uid, uid);
    update_map(map_buf, "/proc/self/uid_map");
    snprintf(map_buf, sizeof(map_buf), "%d %d 1", gid, gid);
    update_map(map_buf, "/proc/self/gid_map");

    // chroot to rootdir
    if (chroot(rootdir) < 0) {
        err_exit("chroot(%s)", rootdir);
    }

    chdir("/");

    SAVE_ENV_VAR(DBUS_SESSION_BUS_ADDRESS);
    SAVE_ENV_VAR(USER);
    SAVE_ENV_VAR(HOSTNAME);
    SAVE_ENV_VAR(LANG);
    SAVE_ENV_VAR(LC_ALL);
    SAVE_ENV_VAR(TERM);
    SAVE_ENV_VAR(DISPLAY);
    SAVE_ENV_VAR(XDG_RUNTIME_DIR);
    SAVE_ENV_VAR(XAUTHORITY);
    SAVE_ENV_VAR(XDG_SESSION_ID);
    SAVE_ENV_VAR(XDG_SEAT);

    clearenv();

    LOAD_ENV_VAR(DBUS_SESSION_BUS_ADDRESS);
    LOAD_ENV_VAR(USER);
    LOAD_ENV_VAR(HOSTNAME);
    LOAD_ENV_VAR(LANG);
    LOAD_ENV_VAR(LC_ALL);
    LOAD_ENV_VAR(TERM);
    LOAD_ENV_VAR(DISPLAY);
    LOAD_ENV_VAR(XDG_RUNTIME_DIR);
    LOAD_ENV_VAR(XAUTHORITY);
    LOAD_ENV_VAR(XDG_SESSION_ID);
    LOAD_ENV_VAR(XDG_SEAT);

    setenv("PATH", "", 1);
    setenv("HOME", "/", 1);
    setenv("TMPDIR", "/tmp", 1);

    /* Run */
    // FIXME: What about arguments in the Exec= line of the desktop file?
    ret = execvp(full_exec, argv);

    if (ret == -1)
        die("Error executing '%s'; return code: %d\n", full_exec, ret);

    free(line);
    free(desktop_file);
    return 0;
}
