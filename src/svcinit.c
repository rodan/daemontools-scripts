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

static void (*selinux_run_init_old) (void);
static void (*selinux_run_init_new) (int argc, char **argv);

int main(int argc, char **argv) {
	char *myargs[32];
	char *myargs2[33];
	void *lib_handle;
	int new = 1;
	myargs[0] = "svcinit";
	myargs2[0] = "svcinit";
	myargs2[1] = "/sbin/runsvcscript.sh";

	while (argv[new] != 0) {
		myargs[new] = argv[new];
		myargs2[new+1] = argv[new];
		new++;
	}
	myargs[new] = (char *) 0;
	myargs2[new+1] = (char *) 0;

	if (argc < 3) {
		execv("/lib/rcscripts/sh/svc-help.sh",myargs);
		exit(1);
	}

	lib_handle = dlopen("/lib/rcscripts/runscript_selinux.so", RTLD_NOW | RTLD_GLOBAL);
	if( lib_handle != NULL ) {
		selinux_run_init_old = dlsym(lib_handle, "selinux_runscript");
		selinux_run_init_new = dlsym(lib_handle, "selinux_runscript2");

		/* use new run_init if it exists, else fall back to old */
		if( selinux_run_init_new != NULL )
			selinux_run_init_new(argc+1,myargs2);
		else if( selinux_run_init_old != NULL )
			selinux_run_init_old();
		else {
			/* this shouldnt happen... probably corrupt lib */
			fprintf(stderr,"Run_init is missing from runscript_selinux.so!\n");
			exit(127);
		}
	}

	if (execv("/sbin/runsvcscript.sh",myargs) < 0)
		exit(1);

	return 0;
}

