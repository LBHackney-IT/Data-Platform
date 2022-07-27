#!/bin/bash
set -eu -o pipefail

date=`date +"%Y%m%d"`

s3_sync_target="s3://test"
s3_sync_source="s3://test"
days_to_retain=5

echo "S3 bucket source: $s3_sync_source"
echo "S3 bucket target: $s3_sync_target"

for i in $(seq 0 $((days_to_retain-1))); do
    date_to_import=$(date +"%Y%m%d" -d "${date} -${i} day")
    date_to_import_hyphen_separated=$(date +"%Y-%m-%d" -d "${date} -${i} day")

    # Include for sync to target: *data=20220727/*
    sync_include_opts+=( --include="*date=$date_to_import/*" )
    # Include for sync to target: *data=2022-07-27/*
    sync_include_opts+=( --include="*date=$date_to_import_hyphen_separated/*" )
    # Include for sync to target: import_year=2022/import_month=07/import_day=27/*
    sync_include_opts+=( --include="import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%-m")/import_day=$(date -d "$date_to_import" "+%-d")/*" )
    # Include for sync to target: import_year=2022/import_month=7/import_day=27/*
    sync_include_opts+=( --include="import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%m")/import_day=$(date -d "$date_to_import" "+%d")/*" )

    # Exclude from source deletion: *data=20220727/*
    rm_exclude_opts+=( --exclude="*date=$date_to_import/*" )
    # Exclude from source deletion: *data=2022-07-27/*
    rm_exclude_opts+=( --exclude="*date=$date_to_import_hyphen_separated/*" )
    # Exclude from source deletion: import_year=2022/import_month=07/import_day=27/*
    rm_exclude_opts+=( --include="import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%-m")/import_day=$(date -d "$date_to_import" "+%-d")/*" )
    # Exclude from source deletion: import_year=2022/import_month=7/import_day=27/*
    rm_exclude_opts+=( --include="import_year=$(date -d "$date_to_import" "+%Y")/import_month=$(date -d "$date_to_import" "+%m")/import_day=$(date -d "$date_to_import" "+%d")/*" )
done

echo ${sync_include_opts[*]}
echo ${rm_exclude_opts[*]}

#echo "Include flags to be used with s3 sync cmd: ${sync_include_opts[*]}"
#echo "Exclude flags to be used with s3 rm cmd: ${rm_exclude_opts[*]}"
#
#echo "Syncing records....."
#aws s3 sync $s3_sync_source $s3_sync_target --acl "bucket-owner-full-control" --exclude "*" "${sync_include_opts[@]}"
#
#echo "Removing old records..."
#aws s3 rm $s3_sync_target --recursive --include "*" "${rm_exclude_opts[@]}"
