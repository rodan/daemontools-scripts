/*
 * Copyright 1999-2006 Gentoo Foundation
 * Distributed under the terms of the GNU General Public License v2
 * $Header: Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <wait.h>
#include <dlfcn.h>

#define EXPECTED_ARGC 3

static void (*selinux_run_init_old) (void);
static void (*selinux_run_init_new) (int argc, char **argv);

int main(int argc, char **argv) {
    char *myargs[EXPECTED_ARGC + 2];
    void *lib_handle;
    myargs[0] = "svcinit";
    myargs[1] = "/usr/bin/runsvcscript.sh";

    if ((argc < EXPECTED_ARGC) || (argc > EXPECTED_ARGC)) {
        execl("/usr/bin/runsvcscript.sh","-h", NULL);
        exit(1);
    }

    myargs[2] = argv[1]; // service_name
    myargs[3] = argv[2]; // (add | remove | start | stop | status)
    myargs[4] = (char *) 0;

    lib_handle = dlopen("/lib/rcscripts/runscript_selinux.so", RTLD_NOW | RTLD_GLOBAL);
    if( lib_handle != NULL ) {
        selinux_run_init_old = dlsym(lib_handle, "selinux_runscript");
        selinux_run_init_new = dlsym(lib_handle, "selinux_runscript2");

        /* use new run_init if it exists, else fall back to old */
        if( selinux_run_init_new != NULL )
            selinux_run_init_new(argc+1,myargs);
        else if( selinux_run_init_old != NULL )
            selinux_run_init_old();
        else {
            /* this shouldnt happen... probably corrupt lib */
            fprintf(stderr,"Run_init is missing from runscript_selinux.so!\n");
            exit(127);
        }
    }

    if (execv("/usr/bin/runsvcscript.sh",&myargs[1]) < 0)
        exit(1);

    return 0;
}
