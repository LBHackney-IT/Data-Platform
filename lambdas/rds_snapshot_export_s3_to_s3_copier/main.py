import os
import logging
import re

import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

s3_client = boto3.client("s3")
glue_client = boto3.client("glue")


def get_date_time(source_identifier: str) -> tuple[str, str, str, str]:
    """
    Gets the year, month, day and date from the source identifier

    Args:
        source_identifier (str): source identifier taken from the
        event, as implemented this will include datetime for the snapshot as
        applicable in the form rds:sql-to-parquet-yy-mm-dd-hhmmss or
        rds:sql-to-parquet-yy-mm-dd-hhmmss-backdated

    Returns:
        tuple(str, str, str, str): year, month, day, date
    """

    pattern = r"^rds:sql-to-parquet-(\d{2})-(\d{2})-(\d{2})-(\d{6})(-backdated)?$"

    if not re.match(pattern, source_identifier):
        raise ValueError("Invalid source identifier format")

    split_identifier = source_identifier.split("-")
    day = split_identifier[5]
    month = split_identifier[4]
    year = "20" + split_identifier[3]

    date = f"{year}{month}{day}"
    return year, month, day, date


def s3_copy_folder(
    s3_client,
    source_bucket: str,
    source_prefix: str,
    target_bucket: str,
    target_prefix: str,
    source_identifier: str,
) -> None:
    """
    Copies parquet files created by an RDS snapshot export from one S3 bucket to another

    Args:
        s3_client (boto3.client): low level S3 client
        source_bucket (str): source bucket for the parquet files
        source_prefix (str): prefix in the source bucket for the parquet files
        target_bucket (str): target bucket for the parquet files
        target_prefix (str): target prefix for the parquet files
        source_identifier (str): to be taken from the event key SourceIdentifier
    """
    paginator = s3_client.get_paginator("list_objects_v2")
    operation_parameters = {"Bucket": source_bucket, "Prefix": source_prefix}
    page_iterator = paginator.paginate(**operation_parameters)
    year, month, day, date = get_date_time(source_identifier)
    for page in page_iterator:
        if "Contents" not in page:
            continue
        for key in page["Contents"]:
            source_key = key["Key"]
            if not source_key.endswith(".parquet"):
                continue
            source_key_split = source_key.split("/")
            parquet_file_name = source_key_split[-1]
            database_name = source_key_split[1]
            table_name = source_key_split[2]
            copy_object_params = {
                "Bucket": target_bucket,
                "CopySource": f"{source_bucket}/{source_key}",
                "Key": f"{target_prefix}{database_name}/{table_name}/import_year={year}/import_month={month}/import_day={day}/import_date={date}/{parquet_file_name}",
                "ACL": "bucket-owner-full-control",
            }
            try:
                s3_client.copy_object(**copy_object_params)
            except Exception as e:
                print(e)


def start_workflow_run(workflow_name: str, glue_client):
    """Starts a Glue workflow run

    Args:
        workflow_name (str): name of the Glue workflow to run
        glue_client (boto3.client): low level Glue client
    """
    try:
        glue_client.start_workflow_run(Name=workflow_name)
    except Exception as e:
        print(e)


def lambda_handler(event, context) -> None:
    print("## EVENT")
    print(event)

    source_bucket = os.environ["SOURCE_BUCKET"]
    target_bucket = os.environ["TARGET_BUCKET"]

    if "TARGET_PREFIX" in os.environ:
        target_prefix = os.environ["TARGET_PREFIX"] + "/"
    else:
        target_prefix = ""

    snapshot_id = event["detail"]["SourceIdentifier"]

    s3_copy_folder(
        s3_client, source_bucket, snapshot_id, target_bucket, target_prefix, snapshot_id
    )

    if "backdated" in snapshot_id.split("-"):
        print("## Backdated Workflow")
        workflow_name = os.environ["BACKDATED_WORKFLOW_NAME"]
        _, _, _, date = get_date_time(snapshot_id)
        glue_client.update_workflow(
            Name=workflow_name, DefaultRunProperties={"import_date": date}
        )
        start_workflow_run(workflow_name, glue_client)
    elif "WORKFLOW_NAME" in os.environ:
        workflow_name = os.environ["WORKFLOW_NAME"]
        start_workflow_run(workflow_name, glue_client)


if __name__ == "__main__":
    lambda_handler("event", "context")
