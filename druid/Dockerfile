FROM openjdk:8

ENV DRUID_VERSION 0.19.0
ENV ZOOKEEPER_VERSION 3.5.8

# Get Druid
RUN mkdir -p /tmp \
    && cd /tmp/ \
    && curl -sL "https://downloads.apache.org/druid/$DRUID_VERSION/apache-druid-$DRUID_VERSION-bin.tar.gz" | tar xvz \
    && mv apache-druid-$DRUID_VERSION /opt/druid

WORKDIR /opt/druid/

# Zookeeper
RUN curl -sL "https://downloads.apache.org/zookeeper/stable/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz" | tar xvz \
    && mv apache-zookeeper-$ZOOKEEPER_VERSION-bin zk

# Expose ports:
# - 8888: HTTP (router)
# - 8081: HTTP (coordinator/overlord)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 2181 2888 3888: ZooKeeper

EXPOSE 8888
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 2181 2888 3888

ENTRYPOINT ./bin/start-micro-quickstart
