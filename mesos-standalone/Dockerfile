FROM radowan/mesos-in-docker:base

LABEL maintainer="radowan <radek.strejc@gmail.com>"

# arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG SPARK_VERSION="2.2.0"
ARG HADOOP_VERSION="2.6"

# environment variables
ENV SPARK_VERSION="${SPARK_VERSION}"
ENV HADOOP_VERSION="${HADOOP_VERSION}"
ENV SPARK_HOME="/opt/spark-${SPARK_VERSION}-bin-hadoop-${HADOOP_VERSION}"

# retrieve new lists of packages
RUN apt-get -y update

# install utils
RUN apt-get -y install \
    mesos marathon chronos

# install docker
RUN wget -qO- https://get.docker.io/gpg | apt-key add - \
    && sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list" \
    && apt-get -y update \
    && curl -sSL https://get.docker.com/ | sh

# install spark
RUN wget "http://mirror.dkm.cz/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -O "/tmp/spark.tgz" \
        && mkdir -p "${SPARK_HOME}" \
        && tar -xzf "/tmp/spark.tgz" --strip 1 -C "${SPARK_HOME}" \
        && rm "/tmp/spark.tgz"

# expose ports
EXPOSE 80 443 2181 2888 3888 5050 5053 4040 4400 7070 7077 8080 8081 8888 8090

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
