import os

import boto3


def get_date_time(source_identifier: str) -> tuple[str, str, str, str]:
    """Gets the year, month, day and date from the source identifier

    Args:
        source_identifier (str): source identifier taken from the
        event, as implemented this will include datetime for the snapshot as
        applicable in the form sql-to-parquet-yy-mm-dd-hhmmss

    Returns:
        tuple(str, str, str, str): year, month, day, date
    """

    split_identifier = source_identifier.split("-")
    day = split_identifier[5]
    month = split_identifier[4]
    year = split_identifier[3]

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
        source_path (str): source key
        target_bucket (str): _description_
        target_path (str): _description_
        snapshot_time (str): _description_
        source_identifier (str): _description_
        is_backdated (bool, optional): _description_. Defaults to False.
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
            database_name = source_key_split("/")[1]
            table_name = source_key_split("/")[2]
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
    s3 = boto3.client("s3")

    source_bucket = os.environ["SOURCE_BUCKET"]
    target_bucket = os.environ["TARGET_BUCKET"]
    if "SOURCE_PREFIX" in os.environ:
        source_prefix = os.environ["SOURCE_PREFIX"]
    else:
        source_prefix = ""
    if "TARGET_PREFIX" in os.environ:
        target_prefix = os.environ["TARGET_PREFIX"] + "/"
    else:
        target_prefix = ""

    snapshot_id = event["detail"]["SnapshotIdentifier"]

    s3_copy_folder(
        s3, source_bucket, source_prefix, target_bucket, target_prefix, snapshot_id
    )

    if "WORKFLOW_NAME" in os.environ:
        workflow_name = os.environ["WORKFLOW_NAME"]
        glue = boto3.client("glue")
        start_workflow_run(workflow_name, glue)


if __name__ == "__main__":
    lambda_handler("event", "context")
