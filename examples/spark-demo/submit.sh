#!/bin/bash 
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

echo "Installing spark on mesos agents"
docker exec -it "mesos-standalone" docker pull radowan/mesos-in-docker:spark-2.2.0-hadoop-2.6 

export http_proxy="" 

echo "Submitting Spark application (compute Pi)"
JSON=$(curl -sSX POST -d@"${SCRIPT_DIR}/pi.json"  --header "Content-Type:application/json;charset=UTF-8" "http://172.18.0.1:7077/v1/submissions/create")

ID=$(echo "${JSON}" | jq -r ".submissionId")
STATUS="QUEUED"

echo "Application ID: ${ID}"
DOTS=1
while [ "${STATUS}" == "RUNNING" ] || [ "${STATUS}" == "QUEUED" ];  do 
	JSON=$(curl -sS "http://172.18.0.1:7077/v1/submissions/status/${ID}" | jq ".")
	STATUS=$(echo "${JSON}" | jq -r ".driverState")
	MESSAGE=$(echo "${JSON}" | jq -r ".message")
    for i in $(seq $DOTS); do echo -n "."; done
    echo -en ".$STATUS\r"
    DOTS=$(($DOTS+1))
	sleep 1;
done
echo ". ${STATUS}"
