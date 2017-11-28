#!/bin/bash -e
SCRIPT=$(readlink -f "${0}")
SCRIPT_BASENAME=$(basename "${SCRIPT}")
SCRIPT_NAME=$(echo "${SCRIPT_BASENAME}" | sed 's/\\..*//')
SCRIPT_DIR=$(dirname "${SCRIPT}")

HOST="172.18.0.1"
SPARK_IMAGE="radowan/mesos-in-docker:spark-2.2.0-hadoop-2.6"

PI_JSON=$(cat <<EOF
{ 
  "action": "CreateSubmissionRequest",
  "appArgs": [],
  "appResource": "http://downloads.mesosphere.com.s3.amazonaws.com/assets/spark/spark-examples_2.10-1.5.0.jar",
  "clientSparkVersion": "2.0.0",
  "environmentVariables": {},
  "mainClass": "org.apache.spark.examples.SparkPi",
  "sparkProperties": {
    "spark.app.name": "org.apache.spark.examples.SparkPi",
    "spark.driver.cores": "1",
    "spark.driver.memory": "512M",
    "spark.executor.memory": "512M",
    "spark.cores.max": "2",
    "spark.jars": "http://downloads.mesosphere.com.s3.amazonaws.com/assets/spark/spark-examples_2.10-1.5.0.jar",
    "spark.master": "mesos://${HOST}",
    "spark.mesos.driver.labels": "DCOS_SPACE:/spark",
    "spark.mesos.executor.docker.forcePullImage": "true",
    "spark.mesos.executor.docker.image": "${SPARK_IMAGE}",
    "spark.ssl.noCertVerification": "true",
    "spark.submit.deployMode": "cluster"
  }
}
EOF
)

echo "Installing spark on mesos agents"
docker exec -it "mesos-standalone" docker pull "${SPARK_IMAGE}"
export http_proxy="" 

echo "Submitting Spark application (compute Pi)"
JSON=$(curl -sSX POST -d"${PI_JSON}"  --header "Content-Type:application/json;charset=UTF-8" "http://${HOST}:7077/v1/submissions/create")

ID=$(echo "${JSON}" | jq -r ".submissionId")
STATUS="QUEUED"

echo "Application ID: ${ID}"
DOTS=1
while [ "${STATUS}" == "RUNNING" ] || [ "${STATUS}" == "QUEUED" ];  do 
	JSON=$(curl -sS "http://${HOST}:7077/v1/submissions/status/${ID}" | jq ".")
	STATUS=$(echo "${JSON}" | jq -r ".driverState")
	MESSAGE=$(echo "${JSON}" | jq -r ".message")
    for i in $(seq $DOTS); do echo -n "."; done
    echo -en ". $STATUS\r"
    DOTS=$(($DOTS+1))
	sleep 1;
done
for i in $(seq $DOTS); do echo -n "."; done
echo ". $STATUS"
