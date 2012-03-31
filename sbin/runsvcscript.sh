#!/bin/bash
# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

# Author: Bruce Guenter <bruceg@em.ca>
# Gentoo facelift by: Petre Rodan <>

[ -z "${SVCDIR}" ] && SVCDIR="/service"
[ -z "${SVCVARDIR}" ] && SVCVARDIR="/var/service"
[ -z "${SVCTIMEOUT}" ] && SVCTIMEOUT=15

# first option is the name of the service
SVC="$1"

# second option is the command to perform on that service
SVCCMD="$2"

# svstat & co try to open the current dir
# and sometimes they won't have privileges to do that
# so we move PWD to a safe location
# ( SELinux related )
cd ${SVCDIR}

# function that returns 0 if $1 is down
svc_isdown() {
	svstat "$1" 2>/dev/null | grep -v ' up ' >/dev/null
}

# function that returns 0 if $1 is up
svc_isup() {
	svstat "$1" 2>/dev/null | grep ' up ' >/dev/null
}

# function that waits ${SVCTIMEOUT} seconds for $1 to start
# if time is exceeded, it returns 1
svc_waitup() {
	[ `svc_isup "$1"` ] && return 0
	sleep 1
	count=1
	while svc_isdown "$1"; do
		echo -n .
		sleep 1
		count=$((${count}+1))
		[ ${count} -gt ${SVCTIMEOUT} ] && return 1
	done
}

# function that waits ${SVCTIMEOUT} seconds for $1 to stop
# if time is exceeded, it returns 1
svc_waitdown() {
	[ `svc_isdown "$1"` ] && return 0
	sleep 1
	count=1
	while svc_isup "$1"; do
		echo -n .
		sleep 1
		count=$((${count}+1))
		[ ${count} -gt ${SVCTIMEOUT} ] && return 1
	done
}

# starts supervise for $1 and bails out if no success after ${SVCTIMEOUT} seconds
start() {
	rm -f "$1/down"
	if ! svok "$1"; then
		echo -n "(supervise"
		count=1
			until svok "$1"; do
				echo -n .
				sleep 1
				count=$((${count}+1))
				if [ ${count} -gt ${SVCTIMEOUT} ]; then
					echo ") "
					echo "error: supervise for '$1' did not start!"
					return 1
				fi
			done
			echo ") "
	fi

	svc -u "$1" && svc_waitup "$1" && echo "$1 started"
}

# stops supervise for $1 and bails out if no success after ${SVCTIMEOUT} seconds 
stop() {
	touch "$1/down"
	if svc_isup "$1"; then
		svc -d "$1"
		if svc_waitdown "$1"; then
			echo "$1 stopped"
		else
			echo "error: failed to stop $1"
		fi
	else
		echo "warning: $1 already down"
	fi
}

# shows for how many seconds a service has been up or down
status() {
	if svok "$1"; then
		# svstat's domain has no rights to write directly to the terminal
		# ( SELinux specific )
		STATUS=`svstat "$1"`
		echo "${STATUS}"
	else
		echo "supervise not running on $1"
	fi
}

# creates a symlink into ${SVCDIR} (/service) from a service 
# present in ${SVCVARDIR} (/var/service)
# the added service will not start automatically
add() {
	if [ -e "${SVCDIR}/${SVC}" ]; then
		echo "error: ${SVC} is already set up."
		return 1
	fi

	if [ ! -x "${SVCVARDIR}/${SVC}/run" ]; then
		echo "error: ${SVCVARDIR}/${SVC} is not a valid supervise script."
		return 1
	fi

	# add the service without starting it
	touch "${SVCVARDIR}/${SVC}/down"
	mkdir -p "${SVCVARDIR}/${SVC}/supervise"
	if [ `${HASLOGGER}` ] ; then
		# compatibility with daemontools < 0.95
		chmod +t "${SVCVARDIR}/${SVC}"
		touch "${SVCVARDIR}/${SVC}/log/down"
		mkdir -p "${SVCVARDIR}/${SVC}/log/supervise"
	else
		chmod -t "${SVCVARDIR}/${SVC}"
	fi

	ln -s "${SVCVARDIR}/${SVC}" "${SVCDIR}/${SVC}" && echo "${SVC} added to service dir"
}

# remove symlink from ${SVCDIR} (/service) and
# stop the supervise process for that service
remove() {

	${HASLOGGER} && svc -dx "$1/log"
	svc -dx "$1" && echo "${SVC} removed from service dir"

	[ -h "$1" ] && rm "$1"
}

usage() {
	sh /lib/rcscripts/sh/svc-help.sh
}

main() {

	SVC=$1
	SVCCMD=$2

	HASLOGGER=false

	if [ ! "${SVCCMD}" = "add" ];then
		if [ ! -x ${SVCDIR}/${SVC}/run ]; then
			echo "error: no such service ${SVC}"
			return 1
		fi
		[ -x ${SVCDIR}/${SVC}/log/run ] && HASLOGGER=true
	else
		[ -x ${SVCVARDIR}/${SVC}/log/run ] && HASLOGGER=true
	fi


	case "${SVCCMD}" in

	start)
		${HASLOGGER} && start ${SVCDIR}/${SVC}/log
		start ${SVCDIR}/${SVC} 
		;;
	stop)
		stop ${SVCDIR}/${SVC}
		${HASLOGGER} && stop ${SVCDIR}/${SVC}/log
		;;
	restart)
		stop ${SVCDIR}/${SVC}
		${HASLOGGER} && stop ${SVCDIR}/${SVC}/log
		${HASLOGGER} && start ${SVCDIR}/${SVC}/log
		start ${SVCDIR}/${SVC}
		;;
	status)
		status ${SVCDIR}/${SVC}
		${HASLOGGER} && status ${SVCDIR}/${SVC}/log
		;;
	add)
		add ${SVC}
		;;
	remove)
		stop ${SVCDIR}/${SVC} &>/dev/null
		${HASLOGGER} && stop ${SVCDIR}/${SVC}/log &>/dev/null
		remove ${SVC}
		;;
	*)
		usage
		exit 1 
		;;
	esac
}

if [ "${SVC}" = "all" -a ! "${SVCCMD}" = "add" -a ! "${SVCCMD}" = "remove" ]; then
	for service in ${SVCDIR}/* ; do
		main `basename ${service}` ${SVCCMD}
	done
else
	main ${SVC} ${SVCCMD}
fi

