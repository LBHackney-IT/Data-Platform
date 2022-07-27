#!/bin/bash
set -eu -o pipefail

date=`date +"%Y%m%d"`

s3_sync_target="s3://${S3_SYNC_TARGET}"
s3_sync_source="s3://${S3_SYNC_SOURCE}"
days_to_retain=${NUMBER_OF_DAYS_TO_RETAIN}

echo "S3 bucket source: $s3_sync_source"
echo "S3 bucket target: $s3_sync_target"

for i in $(seq 0 $((days_to_retain-1))); do
    date_to_import=$(date +"%Y%m%d" -d "${date} -${i} day")
    date_to_import_hyphen_separated=$(date +"%Y-%m-%d" -d "${date} -${i} day")

    # Include for sync from source to target: *date=20220727/*
    sync_include_opts+=( --include="*date=$date_to_import/*" )
    # Include for sync from source to target: *date=2022-07-27/*
    sync_include_opts+=( --include="*date=$date_to_import_hyphen_separated/*" )
    # Include for sync from source to target: *import_year=2022/import_month=7/import_day=27/*
    sync_include_opts+=( --include="*import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%-m")/import_day=$(date -d "$date_to_import" "+%-d")/*" )
    # Include for sync from source to target: *import_year=2022/import_month=07/import_day=27/*
    sync_include_opts+=( --include="*import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%m")/import_day=$(date -d "$date_to_import" "+%d")/*" )
done

date_to_delete=$(date +"%Y%m%d" -d "${date} -${days_to_retain} day")
date_to_delete_hyphen_separated=$(date +"%Y-%m-%d" -d "${date} -${days_to_retain} day")
# Exclude from deletion on target: *date=20220727/*
rm_include_opts+=( --include="*date=$date_to_delete/*" )
# Exclude from deletion on target: *date=2022-07-27/*
rm_include_opts+=( --include="*date=$date_to_delete_hyphen_separated/*" )
# Exclude from deletion on target: *import_year=2022/import_month=7/import_day=27/*
rm_include_opts+=( --include="*import_year=$(date -d "$date_to_delete" "+%Y")/import_month=$(date -d "$date_to_delete" "+%-m")/import_day=$(date -d "$date_to_delete" "+%-d")/*" )
# Exclude from deletion on target: *import_year=2022/import_month=07/import_day=27/*
rm_include_opts+=( --include="*import_year=$(date -d "$date_to_delete" "+%Y")/import_month=$(date -d "$date_to_delete" "+%m")/import_day=$(date -d "$date_to_delete" "+%d")/*" )

echo "Include flags to be used with s3 sync cmd: ${sync_include_opts[*]}"
echo "Include flags to be used with s3 rm cmd: ${rm_include_opts[*]}"

echo "Syncing records....."
aws s3 sync $s3_sync_source $s3_sync_target --acl "bucket-owner-full-control" --exclude "*" "${sync_include_opts[@]}"

echo "Removing old records..."
aws s3 rm $s3_sync_target --recursive --exclude "*" "${rm_include_opts[@]}"
