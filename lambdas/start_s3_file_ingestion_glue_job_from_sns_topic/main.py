import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

glue = boto3.client("glue")


def start_glue_job(source_bucket, target_bucket, key, job_name):
    try:
        response = glue.start_job_run(
            JobName=job_name,
            Arguments={
                "--s3_bucket_source": f"s3://{source_bucket}/{key}",
                "--s3_bucket_target": f"s3://{target_bucket}/{key}",
            },
        )
        logger.info(f"Started Glue job: {job_name} with run ID: {response['JobRunId']}")
        return response
    except Exception as e:
        logger.error(f"Failed to start Glue job {job_name}: {str(e)}")
        raise


def handler(event, context):
    logger.info(f"Received event: {event}")

    target_bucket = os.getenv("TARGET_BUCKET")

    if not target_bucket:
        logger.error("TARGET_BUCKET environment variable not set")
        return {"error": "TARGET_BUCKET environment variable not set"}

    glue_job_name = os.getenv("GLUE_JOB_NAME")

    if not glue_job_name:
        logger.error("GLUE_JOB_NAME environment variable not set")
        return {"error": "GLUE_JOB_NAME environment variable not set"}

    for record in event["Records"]:
        message = json.loads(record["Sns"]["Message"])
        source_bucket = message["bucket"]
        key = message["key"]

        response = start_glue_job(source_bucket, target_bucket, key, glue_job_name)
        return response
