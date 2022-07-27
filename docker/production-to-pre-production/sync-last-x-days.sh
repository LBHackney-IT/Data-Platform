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

    sync_include_opts+=( --include="*date=$date_to_import/*" )
    sync_include_opts+=( --include="*date=$date_to_import_hyphen_separated/*" )

    rm_exclude_opts+=( --exclude="*date=$date_to_import/*" )
    rm_exclude_opts+=( --exclude="*date=$date_to_import_hyphen_separated/*" )
done

echo "Include flags to be used with s3 sync cmd: ${sync_include_opts[*]}"
echo "Exclude flags to be used with s3 rm cmd: ${rm_exclude_opts[*]}"

echo "Syncing records....."
aws s3 sync $s3_sync_source $s3_sync_target --acl "bucket-owner-full-control" --exclude "*" "${sync_include_opts[@]}"

echo "Removing old records..."
aws s3 rm $s3_sync_target --recursive --include "*" "${rm_exclude_opts[@]}"
