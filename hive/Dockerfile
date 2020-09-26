# Alpine 3.11 contains Python 3.8, pyspark only supports Python up to 3.7
FROM alpine:3.10.4

# curl and unzip: download and extract Hive, Hadoop, Spark etc.
# bash: Hadoop is not compatible with Alpine's `ash` shell
# openjdk8: Java
# coreutils: Spark launcher script relies on GNU implementation of `nice`
# procps: Hadoop needs GNU `ps` utility
# findutils: Spark needs GNU `find` to run jobs (weird but true)
# ncurses: so that you can run `yarn top`
RUN apk add --no-cache \
    'curl=~7.66' \
    'unzip=~6.0' \
    'openjdk8' \
    'bash=~5.0' \
    'coreutils=~8.31' \
    'procps=~3.3' \
    'findutils=~4.6' \
    'ncurses=~6.1'

 # Common settings
ENV JAVA_HOME "/usr/lib/jvm/java-1.8-openjdk"
ENV PATH="${PATH}:${JAVA_HOME}/bin"
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Hadoop setup
ENV HADOOP_VERSION=3.2.0
ENV HADOOP_HOME=/usr/hadoop
ENV HADOOP_LOG_DIR="${HADOOP_HOME}/logs"
RUN curl --progress-bar -L --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && mv "/usr/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}" \
 && rm -rf "${HADOOP_HOME}/share/doc" \
 && chown -R root:root "${HADOOP_HOME}"

# Hadoop JVM crashes on Alpine when it tries to load native libraries.
# Solution? Delete those altogether.
# Alternatively, you can try and compile them
# https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/NativeLibraries.html
RUN mkdir "${HADOOP_LOG_DIR}"  \
 && rm -rf "${HADOOP_HOME}/lib/native"

# Hive
ENV HIVE_VERSION=3.1.2
ENV HIVE_HOME=/usr/hive
ENV HIVE_CONF_DIR="${HIVE_HOME}/conf"
RUN curl --progress-bar -L \
  "https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz" \
    | gunzip \
    | tar -x -C /usr/ \
  && mv "/usr/apache-hive-${HIVE_VERSION}-bin" "${HIVE_HOME}" \
  && chown -R root:root "${HIVE_HOME}" \
  && mkdir -p "${HIVE_HOME}/hcatalog/var/log" \
  && mkdir -p "${HIVE_HOME}/var/log" \
  && mkdir -p "${HIVE_CONF_DIR}" \
  && chmod 777 "${HIVE_HOME}/hcatalog/var/log" \
  && chmod 777 "${HIVE_HOME}/var/log" \
  && rm -rf "${HIVE_HOME}/examples"

# Tez
ENV TEZ_VERSION=0.9.1
ENV TEZ_HOME=/usr/tez
RUN curl --progress-bar -L \
  "https://archive.apache.org/dist/tez/${TEZ_VERSION}/apache-tez-${TEZ_VERSION}-bin.tar.gz" \
    | gunzip \
    | tar -x -C /usr/ \
  && mv "/usr/apache-tez-${TEZ_VERSION}-bin" "${TEZ_HOME}" \
  && chown -R root:root "${TEZ_HOME}"

# setup enviroment
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
ENV LD_LIBRARY_PATH="${HADOOP_HOME}/lib/native:${LD_LIBRARY_PATH}"
ENV HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
ENV TEZ_CONF_DIR="${TEZ_HOME}/conf"
ENV TEZ_LIB_DIR="${TEZ_HOME}"
ENV TEZ_JARS="${TEZ_HOME}"
ENV PATH="${PATH}:${HIVE_HOME}/bin:${HADOOP_HOME}/bin"
ENV HADOOP_CLASSPATH="${HADOOP_CLASSPATH}:${HIVE_HOME}/lib/*:${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*"

# If both YARN Web UI and Spark UI is up, then returns 0, 1 otherwise.
HEALTHCHECK CMD curl -f http://host.docker.internal:8080/ \
    && curl -f http://host.docker.internal:8088/ || exit 1

# Multitail for logging
COPY scripts/ /scripts
RUN apk add --no-cache \
    'g++=~8.3' 
RUN apk add --no-cache 'linux-headers=~4.19' \
  && gcc /scripts/watchdir.c -o /scripts/watchdir \
  && chmod +x /scripts/parallel_commands.sh

# Entry point: start all services and applications.
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
