# Examples 

## Using Kafka to ingest data into Druid

* Start the Kafka service (if is stopped): `/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties`
* Create a new topic by `/opt/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic wikipedia`
* Extrat sample data in Kafka container: `gunzip -c /tmp/wikiticker-2015-09-12-sampled.json.gz > /tmp/wikiticker-2015-09-12-sampled.json`
* Publish the messages in the created topic: `export KAFKA_OPTS="-Dfile.encoding=UTF-8"; /opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic wikipedia < /tmp/wikiticker-2015-09-12-sampled.json`
* On Druid [http://localhost:8888](http://localhost:8888), create a supervisor to load data from Kafka;


## Using Hive to ingest data into Druid

In order to use Hive, the following variables need to be set in `hive-site.xml`:

```xml
<property>
    <name>hive.druid.broker.address.default</name>
    <value>druid:8082</value> 
</property>

<property>
    <name>hive.druid.overlord.address.default</name>
    <value>druid:8081</value> 
</property>

<property>
    <name>hive.druid.coordinator.address.default</name>
    <value>druid:8081</value> 
</property>

<property>
    <name>hive.druid.metadata.uri</name>
    <value>jdbc:postgresql://postgresql-hadoop:5432/druid</value> 
</property>

<property>
    <name>hive.druid.metadata.username</name>
    <value>druid</value> 
</property>

<property>
    <name>hive.druid.metadata.password</name>
    <value>FoolishPassword</value> 
</property>

<property>
    <name>hive.druid.metadata.db.type</name>
    <value>postgresql</value> 
</property>

```

To access Hive shell, one can run:  

```bash
$ docker-compose exec hadoop bash
>>> /usr/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

1. First, create a common Hive table and insert some data into it:

```sql
CREATE TABLE base_druid (`__time` timestamp with local time zone, `foo` int, `bar` string);

INSERT INTO base_druid (`__time`, foo, bar) 
VALUES  (current_timestamp(), 1, "test1"), 
        (current_timestamp(), 2, "test2"),
        (current_timestamp(), 3, "test3"),
        (current_timestamp(), 4, "test4"),
        (current_timestamp(), 5, "test5");
```

2. Create an external table. This links an existing Druid Datasource into Hive. This allows you to query some Druid data into Druid and return the result to Hive.

```sql
drop table if exists druid2hive;

CREATE EXTERNAL TABLE druid2hive (
    `__time` timestamp with local time zone, 
    `foo` int, 
    `bar` string) 
    STORED BY 'org.apache.hadoop.hive.druid.DruidStorageHandler' 
    TBLPROPERTIES ("druid.datasource" = "druid_source");

select * from druid2hive;  -- OK

INSERT INTO hive2druid VALUES (current_timestamp(), 9, "test9"); -- ERROR: Cannot insert data into external table backed by Druid"
```

3. Create and insert data via *DruidStorageHandler*. To create, you need to use CTAS (*create table as select*) statement:

```sql
hive> drop table if exists hive2druid;

hive> CREATE TABLE hive2druid STORED 
        BY 'org.apache.hadoop.hive.druid.DruidStorageHandler'
        TBLPROPERTIES (
            "druid.segment.granularity" = "MINUTE", 
            "druid.query.granularity" = "SECOND") 
        AS 
        SELECT cast(`__time` as timestamp with local time zone) as `__time`, 
            foo,
            bar 
            FROM base_druid;

hive> INSERT INTO hive2druid SELECT * FROM base_druid;
-- or
hive> INSERT INTO hive2druidv2 (`__time`, foo, bar) VALUES (current_timestamp(), 10, "test10");
```

4. Use the *Druid Kafka Indexing Service* in Hive to insert data into Druid via Kafka topics.


```sql
hive> drop table if exists hive2kafka;

hive> CREATE TABLE hive2kafka (
    `__time` timestamp with local time zone, 
    `foo` int, 
    `bar` string)
    STORED BY 'org.apache.hadoop.hive.druid.DruidStorageHandler' 
    TBLPROPERTIES (
        "kafka.bootstrap.servers" = "kafka:9092", 
        "kafka.topic" = "hive2kafka", 
        "druid.kafka.ingestion" = "START", 
        "druid.kafka.ingestion.useEarliestOffset" = "true",  
        "druid.kafka.ingestion.maxRowsInMemory" = "500",  
        "druid.kafka.ingestion.startDelay" = "PT1S",  
        "druid.kafka.ingestion.period" = "PT1S",  
        "druid.kafka.ingestion.consumer.retries" = "2");

-- the ingestion is already started, but if not, one can start it
hive> ALTER TABLE hive2kafka2 SET TBLPROPERTIES('druid.kafka.ingestion' = 'START');

hive> INSERT INTO hive2kafka (`__time`, foo, bar) VALUES (current_timestamp(), 11, "test11");
```