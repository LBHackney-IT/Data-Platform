#!/bin/bash
set -eu -o pipefail

# If the import date is not passed in then use today's date - normal process
if [ -z "${IMPORT_DATE_OVERRIDE+x}" ]; then
  DATE=$(date +"%y%m%d")
  SNAPSHOT_DATE=$(date +"%y-%m-%d-%H%M%S")
# Else if the import date is passed in then use that - back dated ingestion
else
# Remove hypens and trim first two characters of date to get year in short format
  DATE="${IMPORT_DATE_OVERRIDE//-/}"
  DATE=${DATE:2}
  SNAPSHOT_DATE="${IMPORT_DATE_OVERRIDE}-backdated"
fi

echo "Date used for import - $DATE"
SNAPSHOT_ID="sql-to-parquet-${SNAPSHOT_DATE}"
echo "Snapshot Id - $SNAPSHOT_ID"
FILENAME="liberator_dump_${DATE}"
DBNAME="liberator"

MYSQL_CONN_PARAMS="--user=${MYSQL_USER} --password=${MYSQL_PASS} --host=${MYSQL_HOST}"

echo "Deleting old snapshots in database..."
python3 delete_db_snapshots_in_db.py

mkdir flatfile
cd flatfile

echo "Copying zip file from s3 bucket to disk..."
SQL_OBJECT_KEY="parking/${FILENAME}.zip"
aws s3 cp s3://"${BUCKET_NAME}"/"${SQL_OBJECT_KEY}" .

# This sleep was added because of an apparent race condition between
# the download and unzipping, where unzip would give an error reading
# from disk
sleep 5

echo "Unzipping file..."
unzip "${FILENAME}".zip

echo "Dropping and recreating RDS database if it exists..."
echo "DROP DATABASE IF EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}
echo "CREATE DATABASE IF NOT EXISTS ${DBNAME}" | mysql ${MYSQL_CONN_PARAMS}

echo "Running SQL from zip into RDS database..."
mysql ${MYSQL_CONN_PARAMS} --database=${DBNAME} < *.sql

echo "Taking snapshot of RDS database..."
aws rds create-db-snapshot --db-instance-identifier "${RDS_INSTANCE_ID}" --db-snapshot-identifier "${SNAPSHOT_ID}"

echo "Done"
