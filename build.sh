#!/bin/bash -e
function out() { echo -e "\e[32m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }

SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

REPO="radowan"
USAGE="${SCRIPT_NAME} - builds docker image

Usage:  ${SCRIPT_NAME} [OPTIONS] <Dockerfile>

Options:
            -p ... push/publish image (same as export PUSH=yes)
            -h ... display this help"

# parse args
while getopts ":ph" opt; do
	case $opt in
    	"p")	PUSH="yes"
                ;;
        "h")    out "${USAGE}"
                exit 0
                ;;
        \?)     err "Invalid option: -$OPTARG"
                exit 1
                ;;
    esac
done
shift $(($OPTIND - 1))
DOCKERFILE="${1}"

# check args
if [ "${DOCKERFILE}" == "" ]; then
    err "Missing argument. Run with -h for details."
    exit 2
fi

# get real path to Dockerfile
DOCKERFILE="$(readlink -f "${DOCKERFILE}")"
if [ ! -f "${DOCKERFILE}" ]; then
    err "Dockerfile ${DOCKERFILE} does not exists or is not a file."
    exit 3
fi

# process images 
NAME="$(basename "$(dirname "${DOCKERFILE}")")"
TAG="${REPO}/${NAME}:latest"
out "Processing ${TAG} ..."

# build image
out "... building"
docker build \
    -t "${TAG}" \
    -f "${DOCKERFILE}" \
    "$(dirname "${DOCKERFILE}")"

# distribute image
if [ "${PUSH}" == "yes" ]; then
    out "... pushing to repo"
    docker push "${TAG}"
fi
out "... done"
