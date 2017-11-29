#!/bin/bash -e

function out() { echo -e "\e[32m${@}\e[39m"; }
function err() { echo -e "\e[31m${@}\e[39m" 1>&2; }
function fail() { err "$@"; exit 1; }

function checkServicePid() {
	if [ "${1}" == "" ]; then fail "Missing pid argument!"; fi
	if $(sleep 0.25 && ps -p "${1}" > /dev/null); then
		out "... running [${1}]"
	else
		fail "... failed to start"
	fi
}

export HOST_IP=$(hostname --all-ip-addresses | awk '{print $1}')

# Docker
out "Starting docker..."
/etc/init.d/docker start

# Zookeeper
out "Starting zookeeper..."
/usr/share/zookeeper/bin/zkServer.sh start &>/dev/null
/usr/share/zookeeper/bin/zkServer.sh status

# Mesos master
out "Starting Mesos Master..."
export MESOS_NATIVE_JAVA_LIBRARY="/usr/lib/libmesos.so"
export MESOS_HOSTNAME="${HOST_IP}"
export MESOS_IP="${HOST_IP}"
export MESOS_ZK="zk://${MESOS_HOSTNAME}:2181/mesos"
export MESOS_PORT="5050"
export MESOS_LOG_DIR="/var/log/mesos"
export MESOS_QUORUM="1"
export MESOS_REGISTRY="in_memory"
export MESOS_WORK_DIR="/var/lib/mesos"
export MESOS_LOGGING_LEVEL="INFO"
export STDOUT_MESOS_MASTER="${MESOS_LOG_DIR}/mesos-master.stdout"
export STDERR_MESOS_MASTER="${MESOS_LOG_DIR}/mesos-master.stderr"
mesos-master 1>"${STDOUT_MESOS_MASTER}" 2>"${STDERR_MESOS_MASTER}" &
checkServicePid $!

# Mesos slave
out "Starting Mesos Slave..."
export MESOS_MASTER="${MESOS_ZK}"
export MESOS_CLUSTER="${MESOS_HOSTNAME}"
export MESOS_ISOLATION="cgroups/cpu,cgroups/mem,cgroups/pids,filesystem/shared,filesystem/linux,volume/sandbox_path"
export MESOS_LAUNCHER="linux"
export STDOUT_MESOS_SLAVE="${MESOS_LOG_DIR}/mesos-slave.stdout"
export STDERR_MESOS_SLAVE="${MESOS_LOG_DIR}/mesos-slave.stderr"
mesos-slave --port=5053 --no-systemd_enable_support --containerizers="mesos,docker" 1>"${STDOUT_MESOS_SLAVE}" 2>"${STDERR_MESOS_SLAVE}" &
checkServicePid $!

# Chronos
out "Starting Chronos..."
export CHRONOS_HOSTNAME="${MESOS_HOSTNAME}"
export STDOUT_CHRONOS="${MESOS_LOG_DIR}/chronos.stdout"
export STDERR_CHRONOS="${MESOS_LOG_DIR}/chronos.stderr"
chronos --no-logger 1>"${STDOUT_CHRONOS}" 2>"${STDERR_CHRONOS}" &
checkServicePid $!

# Marathon
out "Starting Marathon..."
export MARATHON_HOSTNAME="${MESOS_HOSTNAME}"
export MARATHON_ZK="zk://${MESOS_HOSTNAME}:2181/marathon"
export MARATHON_MASTER="${MESOS_ZK}"
export STDOUT_MARATHON="${MESOS_LOG_DIR}/marathon.stdout"
export STDERR_MARATHON="${MESOS_LOG_DIR}/marathon.stderr"
marathon 1>"${STDOUT_MARATHON}" 2>"${STDERR_MARATHON}" &
checkServicePid $!

# Metronome
out "Starting Metronome..."
export METRONOME_LEADER_ELECTION_HOSTNAME="${HOST_IP}"
export METRONOME_MESOS_MASTER_URL="${MESOS_HOSTNAME}:5050"
export METRONOME_ZK_URL="zk://${MESOS_HOSTNAME}:2181/metronome"
export STDOUT_METRONOME="${MESOS_LOG_DIR}/metronome.stdout"
export STDERR_METRONOME="${MESOS_LOG_DIR}/metronome.stderr"
"${METRONOME_HOME}/bin/metronome" 1>"${STDOUT_METRONOME}" 2>"${STDERR_METRONOME}" &
checkServicePid $!

# Spark dispatcher
out "Starting Spark Dispatcher..."
export SPARK_MESOS_DISPATCHER_HOST="${MESOS_HOSTNAME}"
export STDOUT_SPARK="${MESOS_LOG_DIR}/spark.stdout"
export STDERR_SPARK="${MESOS_LOG_DIR}/spark.stderr"
"${SPARK_HOME}/sbin/start-mesos-dispatcher.sh" --master "mesos://${MESOS_HOSTNAME}:5050" 1>"${STDOUT_SPARK}" 2>"${STDERR_SPARK}"
checkServicePid $(ps axf | grep spark | grep -v grep | awk '{print $1}' 2>/dev/null)

# Redis
Out "Starting Redis..."
service redis-server start
service redis-server status

# set ready flag
echo "1" > "/tmp/node.ready"

# pass command
out "Executing ${@}"
${@}
