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
ENV METRONOME_HOME="/opt/metronome"


# retrieve new lists of packages
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && apt-get -y update

# install utils
RUN apt-get -y install \
    mesos marathon chronos sbt libprotobuf-dev protobuf-compiler openjdk-8-jdk-headless

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

# install metronome
RUN wget "https://codeload.github.com/dcos/metronome/zip/master" -O "/tmp/metronome.zip" \
    && unzip "/tmp/metronome.zip" -d "/tmp/metronome/" \
    && mv /tmp/metronome/* "${METRONOME_HOME}"
WORKDIR "${METRONOME_HOME}"
RUN sbt universal:packageBin 

RUN mv $(find "${METRONOME_HOME}" -name "metronome-*.zip" -print | head -1) "/tmp/metronome.zip" \
    && rm -rf "${METRONOME_HOME}"/* \
    && unzip "/tmp/metronome.zip" -d "/tmp/" \
    && mv /tmp/metronome*/* "${METRONOME_HOME}"
    
# clean up
RUN rm -rf ~/.sbt ~/.m2 ~/.ivy2 \
    apt-get purge sbt libprotobuf-dev protobuf-compiler \
    && apt-get autoremove -y --force-yes \
    && apt-get clean

# set workir
WORKDIR "/root"

# expose ports
EXPOSE 80 443 2181 2888 3888 5050 5053 4040 4400 7070 7077 8080 8081 8888 8090

# entry point
ADD "entrypoint.sh" "/usr/local/bin/entrypoint.sh"
ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

# default entrypoint args
CMD ["/bin/bash"]
