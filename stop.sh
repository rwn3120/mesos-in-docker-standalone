#!/bin/bash -e 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

function out() { echo -e "\e[32m${@}\e[39m"; }
function inf() { echo -e "\e[97m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }
function wrn() { echo -e "\e[33m${@}\e[39m" 1>&2; }
function dbg() { if [ "${DBG}" == "true" ]; then echo -e "\e[34m${@}\e[39m"; fi }

# print help if needed
for arg in ${@}; do
	if [ "${arg}" == "-h" ] || [ "${arg}" == "--help" ]; then
		echo "${SCRIPT_NAME} - utility to stop running mesos\n"
        exit 0
	fi
done

NETWORK="mesos-standalone"
HOSTNAME="${NETWORK}"
NAME="${HOSTNAME}"

for c in $(docker ps -a | grep "${NAME}\$" 2>/dev/null| sed 's/.* //'); do 
	wrn "Removing container ${c}"
	docker rm -f "${c}" >> /dev/null 
done
set +e
docker network inspect "${NETWORK}" &> /dev/null
RC=$?
set -e
if [ $RC -eq 0 ]; then
	wrn "Removing network ${NETWORK}"
	docker network rm "${NETWORK}" >> /dev/null
fi

out "${NAME} stopped."
