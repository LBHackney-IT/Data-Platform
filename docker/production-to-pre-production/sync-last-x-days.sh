#!/bin/bash
set -eu -o pipefail

date=`date +"%Y%m%d"`

s3_sync_target="s3://${S3_SYNC_TARGET}"
s3_sync_source="s3://${S3_SYNC_SOURCE}"
days_to_retain=${NUMBER_OF_DAYS_TO_RETAIN}

echo "S3 bucket source: $s3_sync_source"
echo "S3 bucket target: $s3_sync_target"

#*****
#*****
#This script no longer copies the data from production to pre-production
#The data copy is now handled by S3 replication configuration. Please see: terraform/core/35-sync-production-to-pre-production.tf
#This script now only cleans up the data in pre-production that is older than the period defined by the NUMBER_OF_DAYS_TO_RETAIN variable
#*****
#*****

for i in $(seq 0 $((days_to_retain-1))); do
  date_to_retain=$(date +"%Y%m%d" -d "${date} -${i} day")
  date_to_retain_hyphen_separated=$(date +"%Y-%m-%d" -d "${date} -${i} day")

  # Exclude from deletion on target: *date=20220727/*
  rm_exclude_opts+=( --exclude="*date=$date_to_retain/*" )
  # Exclude from deletion on target: *date=2022-07-27/*
  rm_exclude_opts+=( --exclude="*date=$date_to_retain_hyphen_separated/*" )
  # Exclude from deletion on target: *import_year=2022/import_month=7/import_day=27/*
  rm_exclude_opts+=( --exclude="*import_year=$(date -d "$date_to_retain" "+%Y")/import_month=$(date -d "$date_to_retain" "+%-m")/import_day=$(date -d "$date_to_retain" "+%-d")/*" )
  # Exclude from deletion on target: *import_year=2022/import_month=07/import_day=27/*
  rm_exclude_opts+=( --exclude="*import_year=$(date -d "$date_to_retain" "+%Y")/import_month=$(date -d "$date_to_retain" "+%m")/import_day=$(date -d "$date_to_retain" "+%d")/*" )
done


echo "Exclude flags to be used with s3 rm cmd: ${rm_exclude_opts[*]}"

echo "Removing old records..."
aws s3 rm $s3_sync_target --recursive --include "*" "${rm_exclude_opts[@]}"
