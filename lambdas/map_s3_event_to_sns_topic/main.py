import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm = boto3.client("ssm")
sns = boto3.client("sns")


def get_topic_mappings(parameter_name, ssm=None):
    ssm = ssm or boto3.client("ssm")

    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=False)
        parameter_value = response["Parameter"]["Value"]
        topic_mappings = json.loads(parameter_value)
        return topic_mappings
    except Exception as e:
        logger.error(f"Error retrieving or parsing SSM parameter: {e}")
        return {}


def handler(event, context):
    try:
        parameter_name = os.environ["PARAMETER_NAME"]
    except KeyError:
        logger.error("PARAMETER_NAME environment variable not set")
        return {"error": "PARAMETER_NAME environment variable not set"}

    path_to_topic = get_topic_mappings(parameter_name, ssm)

    if not path_to_topic:
        logger.error(f"No topic mappings found in SSM parameter: {parameter_name}")
        return {"error": f"No topic mappings found in SSM parameter: {parameter_name}"}

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        for path, topic_arn in path_to_topic.items():
            if key.startswith(path):
                message = {"bucket": bucket, "key": key}
                response = sns.publish(
                    TopicArn=topic_arn,
                    Message=json.dumps(message),
                    MessageStructure="json",
                )
                logger.info(f"Published message to SNS topic: {topic_arn}")
                logger.info(f"Response: {response}")
                break
