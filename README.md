# Postgres Partitioner

Shell script to partition ALF_NODE_PROPERTIES table on an existing Alfresco Postgres Database.

`ALF_NODE_PROPERTIES` table stores every metadata value for Alfresco objects: contents, folders, users... Commonly, this table is filled with millions of rows, as it stores about 30 properties per node. Using a table partitioning approach improves performance and reduces maintenance operations.

A simple "Node Id" partitioning pattern is currently provided.

The current version of the script has been developed using Postgresql 11.7

This configuration is recommended for bulk ingestion environments, despite is not *officially* supported by Alfresco.

## Partitioning

**Syntax**

```
./alf_pg11_partitioner.sh -dbname <database> -dbhost <database host name> \
-dbuser <database user> -dbpass <database user password> \
-totalnodes <nodes to be indexed> -partitionnodes <nodes for each partition>
```

**Sample**

Partitioning tables storing 100,000 nodes per partition for a Repository including 1 million nodes for a local database.
>> As node_id is used (which is primary on ALF_NODE table), every partition will store at least 30x this number.

```
$ ./alf_pg11_partitioner.sh -dbname alfresco -dbhost 127.0.0.1 -dbuser alfresco -dbpass alfresco \
-totalnodes 1000000 -partitionnodes 100000

Creating partitioned table...
CREATE TABLE
Creating 11 partitions...
Partition 1 from 0 to 100000
CREATE TABLE
Partition 2 from 100000 to 200000
CREATE TABLE
Partition 3 from 200000 to 300000
CREATE TABLE
Partition 4 from 300000 to 400000
CREATE TABLE
Partition 5 from 400000 to 500000
CREATE TABLE
Partition 6 from 500000 to 600000
CREATE TABLE
Partition 7 from 600000 to 700000
CREATE TABLE
Partition 8 from 700000 to 800000
CREATE TABLE
Partition 9 from 800000 to 900000
CREATE TABLE
Partition 10 from 900000 to 1000000
CREATE TABLE
Partition 11 from 1000000 to 1100000
CREATE TABLE
Copying previous data...
INSERT 0 2708
Preparing the new table...
ALTER TABLE
ALTER TABLE
DROP TABLE
```
