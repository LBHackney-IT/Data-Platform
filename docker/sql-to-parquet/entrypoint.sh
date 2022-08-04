#!/bin/bash
set -eu -o pipefail

# If the import date is not passed in then used today's date - normal process
if [ -z "${IMPORT_DATE_OVERRIDE+x}" ]; then
  DATE=$(date +"%y%m%d")
  SNAPSHOT_DATE=$(date +"%y-%m-%d-%H%M%S")
# Else if the import date is passed in then use that - back dated ingestion
else
  DATE="${IMPORT_DATE_OVERRIDE/-/}"
  SNAPSHOT_DATE="${IMPORT_DATE_OVERRIDE}-000000"
fi

echo "Date used for import - $DATE"
SNAPSHOT_ID="sql-to-parquet-${SNAPSHOT_DATE}"
echo "Snapshot Id - $SNAPSHOT_ID"
FILENAME="liberator_dump_${DATE}"
DBNAME="liberator"

#MYSQL_CONN_PARAMS="--user=${MYSQL_USER} --password=${MYSQL_PASS} --host=${MYSQL_HOST}"
#
#python3 delete_db_snapshots_in_db.py
#
#mkdir flatfile
#cd flatfile
#
#SQL_OBJECT_KEY="parking/${FILENAME}.zip"
#aws s3 cp s3://${BUCKET_NAME}/${SQL_OBJECT_KEY} .
#
## This sleep was added because of an apparent race condition between
## the download and unzipping, where unzip would give an error reading
## from disk
#sleep 5
#
#unzip ${FILENAME}.zip
#
#echo "DROP DATABASE IF EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}
#echo "CREATE DATABASE IF NOT EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}
#
#mysql ${MYSQL_CONN_PARAMS} --database=${DBNAME} < *.sql
#aws rds create-db-snapshot --db-instance-identifier ${RDS_INSTANCE_ID} --db-snapshot-identifier ${SNAPSHOT_ID}
