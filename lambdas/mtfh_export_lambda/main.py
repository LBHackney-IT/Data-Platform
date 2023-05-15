import logging
from datetime import datetime
from os import getenv
import json
import boto3

logger = logging.getLogger()


def export_dynamo_db_table(
    client, table_arn, s3_bucket, s3_prefix, s3_account_id, kms_key
):
    try:
        response = client.export_table_to_point_in_time(
            ExportTime=datetime(2023, 4, 3),
            TableArn=table_arn,
            S3Bucket=s3_bucket,
            S3Prefix=s3_prefix,
            ExportFormat="DYNAMODB_JSON",
            S3BucketOwner=s3_account_id,
            S3SseAlgorithm="KMS",
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
    partition_key = f"import_year={t.strftime('%Y')}/import_month={t.strftime('%m')}/import_day={t.strftime('%d')}/import_date={t.strftime('%Y%m%d')}/"  # noqa
    return f"{s3_prefix}{partition_key}"


def get_secret(secret_name):
    secret_name = getenv("SECRET_NAME")
    region_name = getenv("AWS_REGION")
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)
    get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    return get_secret_value_response["SecretString"]


def secret_to_dict(secret):
    return json.loads(secret)


def create_table_arn(table_name, account_id, region):
    return f"arn:aws:dynamodb:{region}:{account_id}:table/{table_name}"


def lambda_handler(event, context):
    s3_bucket = event["s3_bucket"]
    s3_prefix = event["s3_prefix"]
    s3_prefix = add_date_partition_key_to_s3_prefix(s3_prefix)

    region = getenv("AWS_REGION")

    secrets = secret_to_dict(get_secret(getenv("SECRET_NAME")))
    kms_key = secrets["kms_key"]
    role_arn = secrets["role_arn"]
    dynamo_account_id = secrets["dynamo_account_id"]
    s3_account_id = secrets["s3_account_id"]

    sts_client = boto3.client("sts")
    credentials = sts_client.assume_role(
        RoleArn=role_arn, RoleSessionName="export_dynamo_db_table"
    )

    client = boto3.client(
        "dynamodb",
        region,
        aws_access_key_id=credentials["Credentials"]["AccessKeyId"],
        aws_secret_access_key=credentials["Credentials"]["SecretAccessKey"],
        aws_session_token=credentials["Credentials"]["SessionToken"],
    )

    table_arn = create_table_arn(event["table_name"], dynamo_account_id, region)

    response = export_dynamo_db_table(
        client, table_arn, s3_bucket, s3_prefix, s3_account_id, kms_key
    )

    logger.info(f"Exported table {table_arn} to {s3_bucket}/{s3_prefix}: {response}")
    return json.dumps(response, default=str)


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")
