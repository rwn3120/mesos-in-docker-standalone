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

function finalize() {
    if [ $# -gt 1 ]; then
        if [[ $1 = *[[:digit:]]* ]]; then
            RC=$1
        else 
            RC=255
            warn "${1} is not a number. Exiting with ${RC}"
        fi
        MESSAGE="${@:2}"
    else 
        RC=0
        MESSAGE="${@:1}"
    fi
    fx=$(if [[ ${RC} -eq 0 ]]; then echo "out"; else echo "err"; fi)
    if [[ "${MESSAGE}" != "" ]]; then
        ${fx} "${MESSAGE}\nExiting with ${RC}"
    else
        ${fx} "Exiting with ${RC}"
    fi
    exit $RC
}

function handleKill() {
    signal="${1}"
    wrn "Kill signal ${signal} received."
    finalize 254 "Interrupted with ${signal}!"
}

function usage() {
    finalize \
"${SCRIPT_NAME} - utility to run mesos in standalone mode on your local

Usage:
\t${SCRIPT_BASENAME} 
"
}

# set trap
for sig in 1 2 3 8 9 14 15; do
	trap "handleKill ${sig}" $sig;
done

while getopts ":h" opt; do
    case ${opt} in
    	h)  usage
        	exit 0
            ;;
        : ) finalize 8 "Invalid option: -${OPTARG} requires an argument." 1>&2
            ;;
	esac
done
shift $((OPTIND -1))

# images
REPO="radowan"
NAME="mesos-standalone:latest"
IMAGE="${REPO}/${NAME}"

# network
NETWORK="mesos-standalone"
GATEWAY="172.18.0.254"
SUBNET="172.18.0.0/16"
IP="172.18.0.1"
HOSTNAME="${NETWORK}"
NAME="${HOSTNAME}"

# initialize network
set +e
docker network inspect "${NETWORK}" &> /dev/null
RC=$?
set -e
if [ $RC -ne 0 ]; then
    # Create cluster network
    out "Creating network..."
    docker network create --gateway="${GATEWAY}" --subnet="${SUBNET}" "${NETWORK}" >/dev/null
fi

echo -n "Starting ${NAME}..."
cmd="docker run -itd --rm --privileged --net=\"${NETWORK}\" --ip=\"${IP}\" --hostname=\"${HOSTNAME}\" --name=\"${HOSTNAME}\" \"${IMAGE}\""
dbg "${cmd}"
eval ${cmd} >> /dev/null
until docker exec "${HOSTNAME}" ls /tmp/node.ready &>/dev/null; do
	docker ps | grep "${HOSTNAME}" >/dev/null
    echo -n "."
    if [ $? -ne 0 ]; then
    	finalize 14 "Container ${HOSTNAME} died!"
    fi
    sleep 2
done
echo " READY"

out "Master is running on http://${IP}:5050"
