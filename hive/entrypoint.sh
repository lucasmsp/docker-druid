#!/bin/bash

if [ -n "${HADOOP_DATANODE_UI_PORT}" ]; then
  echo "Replacing default datanode UI port 9864 with ${HADOOP_DATANODE_UI_PORT}"
  sed -i "$ i\<property><name>dfs.datanode.http.address</name><value>0.0.0.0:${HADOOP_DATANODE_UI_PORT}</value></property>" ${HADOOP_CONF_DIR}/hdfs-site.xml
fi

if [ -n "${HDFS_FORMAT}" ]; then
  echo "Starting Hadoop name node..."
  yes | hdfs namenode -format
fi

hdfs --daemon start namenode
hdfs --daemon start secondarynamenode
hdfs --daemon start datanode
yarn --daemon start resourcemanager
yarn --daemon start nodemanager
mapred --daemon start historyserver


if [ -n "${HIVE_CONFIGURE}" ]; then
  echo "Configuring Hive..."
  hdfs dfs -mkdir -p /user/root/tez
  hdfs dfs -put /usr/tez/share/tez.tar.gz /user/root/tez/tez.tar.gz

  schematool -dbType postgres -initSchema

  # Start metastore service.
  hive --service metastore &

  # JDBC Server.
  hiveserver2 &

fi

echo "All initializations finished!"

# Blocking call to view all logs. This is what won't let container exit right away.
/scripts/parallel_commands.sh "scripts/watchdir ${HADOOP_LOG_DIR}" "scripts/watchdir ${SPARK_LOG_DIR}"

# Stop all
hdfs namenode -format
hdfs --daemon stop namenode
hdfs --daemon stop secondarynamenode
hdfs --daemon stop datanode
yarn --daemon stop resourcemanager
yarn --daemon stop nodemanager
mapred --daemon stop historyserver

