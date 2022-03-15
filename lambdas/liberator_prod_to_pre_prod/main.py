import boto3
from os import getenv

def lambda_handler(event, lambda_context, s3Client = None):
    s3 = s3Client or boto3.client("s3")

    target_bucket = getenv("TARGET_BUCKET_ID")
    target_prefix = getenv("TARGET_PREFIX")

    resources = event["detail"]["resources"]

    source_object_key_arn = list(filter(lambda x: x["type"] == "AWS::S3::Object", resources))[0]["ARN"]
    source_object_full_path = source_object_key_arn.replace("arn:aws:s3:::", "")
    first_delimiter = source_object_full_path.find('/') 

    source_bucket = source_object_full_path[0:first_delimiter]
    source_object_key = source_object_full_path[first_delimiter + 1:]

    copy_source = {
        'Bucket': source_bucket,
        'Key': source_object_key
    }

    print(f"Copying {source_object_key} from bucket {source_bucket} to bucket {target_bucket} with key {target_prefix}/{source_object_key}")

    s3.copy_object(
        CopySource=copy_source,
        Bucket=target_bucket,
        Key=f"{target_prefix}{source_object_key}"
    )


if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')
