import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
rds = boto3.client("rds")


def lambda_handler(event, context):
    snapshot_identifier = event["detail"]["SourceIdentifier"] + "_s3_export"
    source_arn = event["detail"]["SourceArn"]
    bucket_name = os.environ["BUCKET_NAME"]
    iam_role_arn = os.environ["IAM_ROLE_ARN"]
    kms_key_id = os.environ["KMS_KEY_ID"]

    try:
        rds.export_snapshot_to_s3(
            ExportTaskIdentifier=snapshot_identifier,
            SourceArn=source_arn,
            S3BucketName=bucket_name,
            IamRoleArn=iam_role_arn,
            KmsKeyId=kms_key_id,
        )
        logger.info(
            f"Exported RDS snapshot {snapshot_identifier} to S3 bucket {bucket_name}"
        )
    except ClientError as e:
        logger.error(
            f"Failed to export RDS snapshot {snapshot_identifier} to S3 bucket"
            f" {bucket_name}: {e}"
        )
        raise e


if __name__ == "__main__":
    lambda_handler("event", "context")
