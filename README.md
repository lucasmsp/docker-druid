# Cluster Docker: Apache Druid

This cluster in docker contains Apache Druid (and its dependencies) with a minimal Hadoop ecosystem to perform some basic experiments. More precisely, it provides:

* Apache Druid 0.19.0;
* Apache Kafka;
* Apache Zookeeper 3.5.8 (it a dependency of Druid and Kafka);
* PostgreSQL (used as Druid and Hive metastore)
* Apache Hive 3.1.2;
* Apache Tez 0.9.1;
* Apache Hadoop 3.2.0 (HDFS and Yarn);


### Quickstart

1. Run `docker-compose build` to build this all docker image or
2. Start all cluster services using `docker-compose up` (it may take some time).
3. Once the cluster has started, you can navigate to [http://localhost:8888](http://localhost:8888). 
4. In hadoop container you can access Hive shell to perform some experiments, as follows:

```bash
$ docker-compose exec hadoop bash
>>> /usr/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

A mini tutorial is available in [examples](./examples) folder of how to use Hive to ingest data in Druid or by using Kafka.

#### NOTE: 

 * All project is quite large, for instance, Hadoop image has 1.05GB because contains Hadoop, Hive, and Tez.
 * Also startup may take some time depending on HW resources ...
 * If you want, you may start only a fell components `docker-compose up druid`
 * Hadoop image was based on [panovvv/hadoop-hive-spark-docker](https://github.com/panovvv/hadoop-hive-spark-docker)
