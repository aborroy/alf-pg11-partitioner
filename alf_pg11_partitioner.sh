#!/bin/bash
# Alfresco PostgreSQL 11 partitioner

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Database connections default parameters
PG_DB_NAME="alfresco"
PG_HOST="localhost"
PG_USER="alfresco"
PG_PASS="alfresco"

# Partition data default parameters
NUM_NODES_TOTAL=50000000
NUM_NODES_PARTITION=4000000

function generate {


  echo "Creating partitioned table..."

  PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
       --dbname ${PG_DB_NAME} --username ${PG_USER} \
       --command="CREATE TABLE alf_node_properties_intermediate
          (LIKE alf_node_properties INCLUDING ALL) PARTITION BY RANGE (node_id)"

  PARTITIONS=$((($NUM_NODES_TOTAL / $NUM_NODES_PARTITION) + 1))

  echo "Creating ${PARTITIONS} partitions..."

  for i in `seq 1 $PARTITIONS`;
  do

    MIN=$((($i - 1) * $NUM_NODES_PARTITION))
    MAX=$(($MIN + $NUM_NODES_PARTITION))

    echo "Partition ${i} from ${MIN} to ${MAX}"

    PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
        --dbname ${PG_DB_NAME} --username ${PG_USER} \
        --command="CREATE TABLE alf_node_properties_${i} PARTITION OF alf_node_properties_intermediate
            FOR VALUES FROM (${MIN}) TO (${MAX})"

  done

  echo "Copying previous data..."

  PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
      --dbname ${PG_DB_NAME} --username ${PG_USER} \
      --command="INSERT INTO alf_node_properties_intermediate (
                          node_id,
                          actual_type_n,
                          persisted_type_n,
                          boolean_value,
                          long_value,
                          float_value,
                          double_value,
                          string_value,
                          serializable_value,
                          qname_id,
                          list_index,
                          locale_id
                  )
                      SELECT node_id,
                      actual_type_n,
                      persisted_type_n,
                      boolean_value,
                      long_value,
                      float_value,
                      double_value,
                      string_value,
                      serializable_value,
                      qname_id,
                      list_index,
                      locale_id
                      FROM alf_node_properties"

  echo "Preparing the new table..."

  PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
      --dbname ${PG_DB_NAME} --username ${PG_USER} \
      --command="ALTER TABLE alf_node_properties RENAME TO alf_node_properties_retired"

  PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
      --dbname ${PG_DB_NAME} --username ${PG_USER} \
      --command="ALTER TABLE alf_node_properties_intermediate RENAME TO alf_node_properties"

  PGPASSWORD="${PG_PASS}" psql --host ${PG_HOST} \
      --dbname ${PG_DB_NAME} --username ${PG_USER} \
      --command="DROP TABLE alf_node_properties_retired"
}

# EXECUTION
# Parse params from command line
while test $# -gt 0
do
    case "$1" in
        -dbname)
            PG_DB_NAME=$2
            shift
        ;;
        -dbhost)
            PG_HOST=$2
            shift
        ;;
        -dbuser)
            PG_USER=$2
            shift
        ;;
        -dbpass)
            PG_PASS=$2
            shift
        ;;
        -totalnodes)
            NUM_NODES_TOTAL=$2
            shift
        ;;
        -partitionnodes)
            NUM_NODES_PARTITION=$2
            shift
        ;;
        *)
            echo "An invalid parameter was received: $1"
            echo "Allowed parameters:"
            echo "  -dbname"
            echo "  -dbhost"
            echo "  -dbuser"
            echo "  -dbpass"
            echo "  -totalnodes"
            echo "  -partitionnodes"
            exit 1
        ;;
    esac
    shift
done

# Generating DB partitions
generate
