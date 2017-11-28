#!/bin/bash -e 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

"${SCRIPT_DIR}/stop.sh"
"${SCRIPT_DIR}/start.sh"
