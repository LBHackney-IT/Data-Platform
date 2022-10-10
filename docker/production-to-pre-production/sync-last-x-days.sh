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

for i in $(seq 0 $((10))); do

  # This process runs weekly, delete the 10 days just before the retention period
  # Example. Retain 2 days, current date is 2022-08-04 so delete 2202-8-02 -> 2022-07-26
  date_to_retain=$(date +"%Y%m%d" -d "${date} -${days_to_retain} day -${i} day")
  date_to_retain_hyphen_separated=$(date +"%Y-%m-%d" -d "${date} -${days_to_retain} day -${i} day")
  # Include for deletion on target: *date=20220726/*
  rm_include_opts+=( --include="*date=$date_to_retain/*" )
  # Include for deletion on target: 20220726/*
  rm_include_opts+=( --include="$date_to_retain/*" )
  # Include for deletion on target: *date=2022-07-26/*
  rm_include_opts+=( --include="*date=$date_to_retain_hyphen_separated/*" )
  # Include for deletion on target: *import_year=2022/import_month=7/import_day=26/*
  rm_include_opts+=( --include="*import_year=$(date -d "$date_to_retain" "+%Y")/import_month=$(date -d "$date_to_retain" "+%-m")/import_day=$(date -d "$date_to_retain" "+%-d")/*" )
  # Include for deletion on target: *import_year=2022/import_month=07/import_day=26/*
  rm_include_opts+=( --include="*import_year=$(date -d "$date_to_retain" "+%Y")/import_month=$(date -d "$date_to_retain" "+%m")/import_day=$(date -d "$date_to_retain" "+%d")/*" )
done

echo "Include flags to be used with s3 rm cmd: ${rm_include_opts[*]}"

echo "Removing old records..."
aws s3 rm $s3_sync_target --recursive --exclude "*" "${rm_include_opts[@]}"
