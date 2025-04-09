"""
Script to call the GovNotify API to retrieve data from the
Housing LBH Communal Repairs account and write to S3.
Retrieved data is written to S3 Landing as a json string.
Data is then normalised and written to s3 Raw for use by analysts.
Raw zone is crawled so that data is exposed in the Glue data catalog.
"""

from datetime import datetime
from io import BytesIO
import json
import logging
from os import getenv
import re

from botocore.exceptions import ClientError
import boto3
from notifications_python_client.notifications import NotificationsAPIClient
from notifications_python_client.errors import HTTPError
import pandas as pd

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def initialize_s3_client():
    """
    Initialise and return an AWS S3 client using default credentials.

    Returns:
        boto3.client: S3 client instance.
    """
    return boto3.client('s3')


def get_api_secret(api_secret_name, region_name):
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)
    try:
        get_secret_value_response = client.get_secret_value(SecretId=api_secret_name)
    except ClientError as e:
        raise e
    return get_secret_value_response["SecretString"]


def initialise_notification_client(api_key):
    """
    Initialise and return a GovNotify Python API client using api key (secret).
    Args:
        api_key (str)

    Returns:
        GovNotify Python API client instance
    """
    return NotificationsAPIClientAllJobs(api_key)


class NotificationsAPIClientAllJobs(NotificationsAPIClient):

    def get_all_notifications_iterator_all_jobs(self, status=None, template_type=None, reference=None, older_than=None,
                                                include_jobs=None):
        result = self.get_all_notifications(status, template_type, reference, older_than, include_jobs)
        notifications = result.get("notifications")
        while notifications:
            yield from notifications
            next_link = result["links"].get("next")
            notification_id = re.search("[0-F]{8}-[0-F]{4}-[0-F]{4}-[0-F]{4}-[0-F]{12}", next_link, re.I).group(0)
            result = self.get_all_notifications(status, template_type, reference, notification_id, include_jobs)
            notifications = result.get("notifications")


def get_response(query):
    try:
        response = query
    except HTTPError as e:
        logger.error(
            f"Error requesting response from {query}: {e}"
        )
        raise
    return response


def prepare_json(response):
    return json.dumps(response).encode('utf-8')


def upload_to_s3(s3_bucket_name, s3_client, file_content, file_name):
    """
    Upload file content to AWS S3.

    Args:
        s3_bucket_name (): Name of S3 bucket.
        s3_client (boto3.client): S3 client instance.
        file_content (bytes): File content as bytes.
        file_name (str): Name of the file in S3.

    Returns:
        None
    """
    try:
        s3_client.put_object(Bucket=s3_bucket_name, Key=file_name, Body=file_content)
        logger.info(f"Uploaded {file_name} to S3")
    except Exception as e:
        logger.error(f"Error uploading {file_name} to S3: {str(e)}")


def json_to_parquet_normalised(response, label):
    """
    Args:
        response (json str): json string containing json response from API
        label (str): Name of the api endpoint 'table' retrieved.
    return:
        parquet buffer object
    """
    df = pd.json_normalize(response)
    parquet_buffer = BytesIO()
    df.to_parquet(parquet_buffer, index=False, engine='pyarrow')
    return parquet_buffer


def add_date_partition_key_to_s3_prefix(s3_prefix):
    t = datetime.today()
    partition_key = f"import_year={t.strftime('%Y')}/import_month={t.strftime('%m')}/import_day={t.strftime('%d')}/import_date={t.strftime('%Y%m%d')}/"  # noqa
    return f"{s3_prefix}{partition_key}"


def lambda_handler(event, context):
    logger.info("Set up S3 client...")
    s3_client = boto3.client('s3')
    glue_client = boto3.client('glue')

    api_secret_name = getenv("API_SECRET_NAME")
    region_name = getenv("AWS_REGION")
    file_name = 'notifications'

    output_s3_bucket_landing = getenv("TARGET_S3_BUCKET_LANDING")
    output_s3_bucket_raw = getenv("TARGET_S3_BUCKET_RAW")
    output_folder = getenv("TARGET_S3_FOLDER")
    crawler_raw = getenv("CRAWLER_NAME_RAW")

    logger.info("Get API secret...")
    api_secret_string = get_api_secret(api_secret_name, region_name)
    api_secret_json = json.loads(api_secret_string)
    api_key = api_secret_json.get("api_key_live")
    client = initialise_notification_client(api_key)

    logger.info("Get all notifications through iterator...")

    response = client.get_all_notifications_iterator_all_jobs(template_type='sms', include_jobs=True)

    # write iterator items to a list as items will be finite
    response_list = list(response)

    output_folder_json = add_date_partition_key_to_s3_prefix(f'{output_folder}{file_name}/json/')
    output_folder_parquet = add_date_partition_key_to_s3_prefix(f'{output_folder}{file_name}/parquet/')

    # convert response to json formatted string
    json_str = prepare_json(response=response_list)

    # Upload the json string to landing only
    upload_to_s3(output_s3_bucket_landing, s3_client, json_str, f'{output_folder_json}{file_name}.json')

    # Upload parquet buffer to S3 raw; run crawler
    parquet_buffer_raw = json_to_parquet_normalised(response=response_list, label=file_name)
    parquet_buffer_raw.seek(0)
    s3_client.upload_fileobj(parquet_buffer_raw, output_s3_bucket_raw,
                             f'{output_folder_parquet}{file_name}.parquet')
    glue_client.start_crawler(Name=f'{crawler_raw} {file_name}')

    logger.info("Job finished")


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")
