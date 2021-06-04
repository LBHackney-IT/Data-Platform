#!/bin/bash
set -eu -o pipefail

DATE=`date +"%y%m%d"`

FILENAME="liberator_dump_${DATE}"
DBNAME="liberator"

DATE=`date +"%y-%m-%d-%H%M%S"`
SNAPSHOT_ID="sql-to-parquet-${DATE}"
MYSQL_CONN_PARAMS="--user=${MYSQL_USER} --password=${MYSQL_PASS} --host=${MYSQL_HOST}"

python3 delete_db_snapshots_in_db.py

mkdir flatfile
cd flatfile

SQL_OBJECT_KEY="parking/${FILENAME}.zip"
aws s3 cp s3://${BUCKET_NAME}/${SQL_OBJECT_KEY} .

# This sleep was added because of an apparent race condition between
# the download and unzipping, where unzip would give an error reading
# from disk
sleep 5

unzip ${FILENAME}.zip

echo "DROP DATABASE IF EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}
echo "CREATE DATABASE IF NOT EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}

mysql ${MYSQL_CONN_PARAMS} --database=${DBNAME} < *.sql
aws rds create-db-snapshot --db-instance-identifier ${RDS_INSTANCE_ID} --db-snapshot-identifier ${SNAPSHOT_ID}
