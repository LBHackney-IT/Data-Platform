import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
rds = boto3.client("rds")

BUCKET_NAME = os.environ["BUCKET_NAME"]
IAM_ROLE_ARN = os.environ["IAM_ROLE_ARN"]
KMS_KEY_ID = os.environ["KMS_KEY_ID"]


def lambda_handler(event, context):
    print("## EVENT")
    print(event)

    snapshot_identifier = event["detail"]["SourceIdentifier"]
    source_arn = event["detail"]["SourceArn"]

    try:
        rds.start_export_task(
            ExportTaskIdentifier=snapshot_identifier,
            SourceArn=source_arn,
            S3BucketName=BUCKET_NAME,
            IamRoleArn=IAM_ROLE_ARN,
            KmsKeyId=KMS_KEY_ID,
        )
        logger.info(
            f"Exported RDS snapshot {snapshot_identifier} to S3 bucket {BUCKET_NAME}"
        )
    except ClientError as e:
        logger.error(
            f"Failed to export RDS snapshot {snapshot_identifier} to S3 bucket"
            f" {BUCKET_NAME}: {e}"
        )
        raise e


if __name__ == "__main__":
    lambda_handler("event", "context")
