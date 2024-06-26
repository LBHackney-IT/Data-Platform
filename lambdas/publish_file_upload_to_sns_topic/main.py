import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    topic_arn = os.environ["TOPIC_ARN"]
    sns = boto3.client("sns")

    logger.info("## event")
    logger.info(event)

    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    file_key = event["Records"][0]["s3"]["object"]["key"]
    event_time = event["Records"][0]["eventTime"]

    message = f"File uploaded: {file_key} to bucket: {bucket_name} at: {event_time}"
    subject = f"New File Uploaded to S3: {bucket_name}/{file_key}"

    sns.publish(
        TopicArn=topic_arn,
        Message=message,
        Subject=subject,
    )

    return {
        "statusCode": 200,
        "body": json.dumps("Email notification sent successfully!"),
    }
