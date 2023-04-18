import json
import logging
import os
from datetime import datetime

import boto3

logger = logging.getLogger()


def export_dynamo_db_table(
    client,
    table_arn,
    s3_bucket,
    s3_prefix=None,
    export_format="DYNAMODB_JSON",
    s3_bucket_owner_id=None,
    s3_ss3_algorithm="KMS",
    kms_key=None,
):
    try:
        response = client.export_table_to_point_in_time(
            ExportTime=datetime.now(),
            TableArn=table_arn,
            S3Bucket=s3_bucket,
            S3Prefix=s3_prefix,
            ExportFormat=export_format,
            S3BucketOwner=s3_bucket_owner_id,
            S3SseAlgorithm=s3_ss3_algorithm,
            S3SseKmsKeyId=kms_key,
        )
    except Exception as e:
        logger.error(
            f"Error exporting table {table_arn} to {s3_bucket}/{s3_prefix}: {e}"
        )
        raise
    return response


def add_date_partition_key_to_s3_prefix(s3_prefix):
    t = datetime.today()
    partition_key = f"import_year={t.strftime('%Y')}/import_month={t.strftime('%m')}/import_day={t.strftime('%d')}/import_date={t.strftime('%Y%m%d')}/"
    return f"{s3_prefix}{partition_key}"


def lambda_handler(event, context):
    s3_bucket_owner_id = os.getenv("S3_BUCKET_OWNER_ID")
    role_arn = event["secrets"]["role_arn"]
    s3_bucket = event["s3_bucket"]
    s3_prefix = event["s3_prefix"]
    s3_prefix = add_date_partition_key_to_s3_prefix(s3_prefix)

    sts_client = boto3.client("sts")
    credentials = sts_client.assume_role(
        RoleArn=role_arn, RoleSessionName="export_dynamo_db_table"
    )

    client = boto3.client(
        "dynamodb",
        region_name=os.getenv("AWS_REGION"),
        aws_access_key_id=credentials["Credentials"]["AccessKeyId"],
        aws_secret_access_key=credentials["Credentials"]["SecretAccessKey"],
        aws_session_token=credentials["Credentials"]["SessionToken"],
    )

    table_arn = os.path.join(event["secrets"]["table_arn_pre"], event["table_name"])
    kms_key = event["secrets"]["kms_key"]

    response = export_dynamo_db_table(
        client=client,
        table_arn=table_arn,
        s3_bucket=s3_bucket,
        s3_prefix=s3_prefix,
        s3_bucket_owner_id=s3_bucket_owner_id,
        kms_key=kms_key,
    )

    logger.info(f"Exported table {table_arn} to {s3_bucket}/{s3_prefix}: {response}")
    return json.dumps(response, default=str)
