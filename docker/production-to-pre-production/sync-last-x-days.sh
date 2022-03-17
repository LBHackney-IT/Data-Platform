#!/bin/bash

# sync 60 days raw zone

date=`date +"%Y%m%d"` # 20220316

s3_sync_target="s3://${S3_SYNC_TARGET}"
s3_sync_source="s3://${S3_SYNC_SOURCE}"
days_to_retain=${NUMBER_OF_DAYS_TO_RETAIN}
list_of_dates_to_retain=""

echo $s3_sync_source
echo $s3_sync_target
include_opts=[]
for i in $(seq 0 $((days_to_retain-1))); do
    date_to_import=$(date -v "-${i}d" +"%Y%m%d")
    include_opts+=( --include="*date=$date_to_import/*" )
    echo $date_to_import
    # list_of_dates_to_retain+="${d},"
done

echo $exclude_opts

aws s3 sync $s3_sync_source $s3_sync_target \
    --exclude "*" "${include_opts[@]}" \
    #  --exclude "*" --include="*date=20220317/* --include="*date=20220316/*" ....
    --acl "bucket-owner-full-control" \
    --dryrun

# Remove trailing comma
# list_of_dates_to_retain=${list_of_dates_to_retain%?}

# echo $list_of_dates_to_retain
# echo "*date=[$list_of_dates_to_retain]*"

# aws s3 sync $s3_sync_source $s3_sync_target \
    # --exclude "*" --include "*date=[$list_of_dates_to_retain]/*" \
    # --acl "bucket-owner-full-control" \
    # --dryrun

# remove records older than 60 days
# python3 remove_old_data.py
