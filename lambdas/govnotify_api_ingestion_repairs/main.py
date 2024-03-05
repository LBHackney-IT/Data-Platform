"""
Script to call the GovNotify API to retrieve data. Writes response as a
JSON string and Parquet file into the landing zone.
"""
from datetime import datetime
from io import BytesIO
import json
import logging
from os import getenv

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
    return NotificationsAPIClient(api_key)


def get_response(query):
    try:
        response = query
    except HTTPError as e:
        logger.error(
            f"Error requesting response from {query}: {e}"
        )
        raise
    return response


def upload_to_s3(s3_bucket_name, s3_client, file_content, file_name):
    """
    Upload file content to AWS S3.

    Args:
        s3_bucket_name ():
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


def json_to_parquet(response, label):
    """

    Args:
        response (dict):
        label ():

    Returns:

    """
    df = pd.DataFrame.from_dict(response[label])
    parquet_buffer = BytesIO()
    df.to_parquet(parquet_buffer, index=False, engine='pyarrow')
    return parquet_buffer


def prepare_json(response):
    return json.dumps(response).encode('utf-8')


def add_date_partition_key_to_s3_prefix(s3_prefix):
    t = datetime.today()
    partition_key = f"import_year={t.strftime('%Y')}/import_month={t.strftime('%m')}/import_day={t.strftime('%d')}/import_date={t.strftime('%Y%m%d')}/"  # noqa
    return f"{s3_prefix}{partition_key}"


def lambda_handler(event, context):
    logger.info(f"Set up S3 client...")
    s3_client = boto3.client('s3')

    api_secret_name = getenv("API_SECRET_NAME")
    region_name = getenv("AWS_REGION")

    output_s3_bucket = getenv("TARGET_S3_BUCKET")
    output_folder = getenv("TARGET_S3_FOLDER")

    output_folder = add_date_partition_key_to_s3_prefix(output_folder)

    logger.info(f"Get API secret...")
    api_secret_string = get_api_secret(api_secret_name, region_name)
    api_secret_json = json.loads(api_secret_string)
    api_key = api_secret_json.get("api_key_live")
    client = initialise_notification_client(api_key)

    # GovNotify queries to retrieve
    api_queries = ['notifications', 'received_text_messages']
    api_queries_dict = {
        'notifications': {'query': client.get_all_notifications(include_jobs=True),
                          'file_name': 'notifications'},
        'received_text_messages': {'query': client.get_received_texts(),
                                   'file_name': 'received_text_messages'}
    }

    logger.info(f"Get API responses...")
    for api_query in api_queries:
        query = api_queries_dict.get(api_query).get('query')
        response = get_response(query)
        file_name = api_queries_dict.get(api_query).get('file_name')

        json_str = prepare_json(response=response)
        parquet_buffer = json_to_parquet(response=response, label=file_name)
        parquet_buffer.seek(0)

        # Upload the json string and parquet buffer to S3
        upload_to_s3(output_s3_bucket, s3_client, json_str, f'{output_folder}json/{file_name}.json')
        s3_client.upload_fileobj(parquet_buffer, output_s3_bucket, f'{output_folder}parquet/{file_name}.parquet')

        logger.info(f"Responses written as json and parquet to {output_s3_bucket}/{output_folder}{file_name}")


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")
