/*
 * This file is based on @lethalman's nix-user-chroot. This file has
 * diverged from it though.
 *
 * Usage: nix-user-chroot <nixpath> <command>
 */

#define _GNU_SOURCE
#include <sched.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <signal.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <errno.h>
#include <sys/mount.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>

#define err_exit(format, ...) { fprintf(stderr, format ": %s\n", ##__VA_ARGS__, strerror(errno)); exit(EXIT_FAILURE); }

static void usage(char *pname) {
    fprintf(stderr, "Usage: %s <nixpath> <command>\n", pname);

    exit(EXIT_FAILURE);
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
    char path_buf2[PATH_MAX];

    snprintf(path_buf, sizeof(path_buf), "/%s", name);

    struct stat statbuf;
    if (stat(path_buf, &statbuf) < 0) {
        fprintf(stderr, "Cannot stat %s: %s\n", path_buf, strerror(errno));
        return;
    }

    snprintf(path_buf2, sizeof(path_buf2), "%s/%s", rootdir, name);

    if (S_ISDIR(statbuf.st_mode)) {
        mkdir(path_buf2, statbuf.st_mode & ~S_IFMT);
        if (mount(path_buf, path_buf2, "none", MS_BIND | MS_REC, NULL) < 0) {
            fprintf(stderr, "Cannot bind mount %s to %s: %s\n", path_buf, path_buf2, strerror(errno));
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        usage(argv[0]);
    }

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

    // determine absolute directory for nix dir
    char *nixdir = realpath(argv[1], NULL);
    if (!nixdir) {
        err_exit("realpath(%s)", argv[1]);
    }

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
    add_path("tmp", rootdir);
    add_path("var", rootdir);

    // make sure nixdir exists
    struct stat statbuf2;
    if (stat(nixdir, &statbuf2) < 0) {
        err_exit("stat(%s)", nixdir);
    }

    // mount /nix to new namespace
    char path_buf[PATH_MAX];
    snprintf(path_buf, sizeof(path_buf), "%s/nix", rootdir);
    mkdir(path_buf, statbuf2.st_mode & ~S_IFMT);
    if (mount(nixdir, path_buf, "none", MS_BIND | MS_REC, NULL) < 0) {
        err_exit("mount(%s, %s)", nixdir, path_buf);
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

    // execute the command
    execvp(argv[2], argv+2);
    err_exit("execvp(%s)", argv[2]);
}
