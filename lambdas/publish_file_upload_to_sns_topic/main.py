import json

import boto3

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
        print(f"Error retrieving or parsing SSM parameter: {e}")
        return {}


def handler(event, context):
    path_to_topic = get_topic_mappings(ssm)

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        for path, topic_arn in path_to_topic.items():
            if key.startswith(path):
                message = {"bucket": bucket, "key": key}
                sns.publish(
                    TopicArn=topic_arn,
                    Message=json.dumps({"default": json.dumps(message)}),
                    MessageStructure="json",
                )
                break
