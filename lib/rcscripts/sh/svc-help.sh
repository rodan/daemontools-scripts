#!/bin/bash
# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:  Exp $

BLUE="\033[34;01m"
GREEN="\033[32;01m"
OFF="\033[0m"
CYAN="\033[36;01m"

myservice='svcinit'
[ -z "${SVCDIR}" ] && SVCDIR="/service"
[ -z "${SVCVARDIR}" ] && SVCVARDIR="/var/service"

echo -e "
${GREEN}Script that controls daemontools svc services ${BLUE}http://www.gentoo.org/${OFF}
 Copyright 2001-2004 Gentoo Technologies, Inc.; Distributed under the GPL

Usage: ${CYAN}${myservice}${OFF} ${GREEN}service_name${OFF} ${GREEN}options${OFF}

${CYAN}service_name:${OFF}

    ${GREEN}for services that are not yet supervised${OFF}
      These are the entries present in the ${BLUE}${SVCVARDIR}${OFF} directory
      If you have merged daemontools-scripts with USE=withsamplescripts,
      you will have a collection of samples in that place.
      The only valid option in this case is ${GREEN}add${OFF}.

    ${GREEN}for services that are already supervised${OFF}
      These are the services are already present in the ${BLUE}${SVCDIR}${OFF}
      directory. The following options can be used for them:
      ${GREEN}start${OFF}, ${GREEN}stop${OFF}, ${GREEN}restart${OFF}, ${GREEN}status${OFF} and ${GREEN}remove${OFF}
      ${CYAN}service_name${OFF} is either the entry in the ${BLUE}${SVCDIR}${OFF} directory
      or the ${GREEN}all${OFF} keyword.

${CYAN}options:${OFF}

    ${GREEN}start${OFF}
      Signals supervise to start the given service. Waits for success for a 
      maximum time limit after which it exits.

    ${GREEN}stop${OFF}
      Signals supervise to stop the service. Waits for success for a 
      maximum time limit after which it exits.

    ${GREEN}restart${OFF}
      a ${GREEN}stop${OFF} followed by a ${GREEN}start${OFF}.

    ${GREEN}add${OFF}
      Makes a sevice supervisable by creating a symlink inside ${BLUE}${SVCDIR}${OFF}
      directed to the service collection ( ${BLUE}${SVCVARDIR}${OFF} )

    ${GREEN}remove${OFF}
      Removes the selected entry from ${BLUE}${SVCDIR}${OFF}
      This option will stop the service and the supervising process.

    ${GREEN}status${OFF}
      Shows for how many seconds a service has been started or stopped.

"

