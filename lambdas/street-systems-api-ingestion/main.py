"""
Script for getting the Street System traffic counters data.

"""

import boto3
import json
import re
import datetime
import logging
import pandas as pd
import requests
import s3fs
from os import getenv

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name):
    response = secrets_manager_client.get_secret_value(
        SecretId=secret_name,
    )
    return response


def refresh_token(url, user, secret):
    e = url + '/refresh_token'
    d = {'device_id': user, 'secret': secret}
    response = requests.put(url=e, json=d)
    resp_j = response.json()
    token = resp_j['token']
    return token


def get_data(url, user, token, location, from_s, to_s):
    """
          Get data from API call

          Args:
              url (str): API url
              user (str): username from retrieve_credentials_from_secrets_manager
              token (str): token from retrieve_credentials_from_secrets_manager
              location (str): all for all locations
              from_s (datetime): initial datetime of the range
              to_s (datetime): end datetime of the range

          Returns:
              API response
    """
    e = url + '/traffic/counts'
    d = {
        'user': user,
        'token': token,
        'location': location,
        'from': from_s,
        'to': to_s
    }

    response = requests.get(url=e, json=d)
    return response


def filter_data(resp_json, accepted_classes):
    """
            Filter the API response

            Args:
                resp_json (json): response from get_data
                accepted_classes (str): empty for all the classes # accepted_classes = ['person','car','pc','head']
            Returns:
                filtered API response
            """
    filtered = []
    for dictor in resp_json:
        if dictor['veh_class'] in accepted_classes:
            # if dictor['veh_class']:
            filtered_1 = {'variable': dictor['dir'], 'unit': dictor['veh_class'], 'sensor_name': dictor['location'],
                          'reading': dictor['value'],
                          'timestamp': (datetime.datetime.strptime(dictor['dt'], "%a, %d %b %Y %H:%M:%S GMT")).strftime(
                              "%Y%m%dT%H%M%SZ")}
            filtered.append(filtered_1)
    return filtered


def write_dataframe_to_s3_parquet(s3_client, s3_bucket, output_folder, df, filename):
    """
       Write dataframe to S3 parquet.

       Args:
           s3_client (bot3.client): S3 client instance.
           s3_bucket (str): S3 bucket.
           output_folder (str): output folder name.
           df (dataframe): dataframe to be transformed into parquet
           file_name (str): Name of the file in S3.

       Returns:
           None
       """
    filename = re.sub('[^a-zA-Z0-9]+', '-', filename).lower()
    current_date = datetime.datetime.now()
    day = single_digit_to_zero_prefixed_string(current_date.day)
    month = single_digit_to_zero_prefixed_string(current_date.month)
    year = str(current_date.year)
    date = year + month + day
    path = f"s3://{s3_bucket}/{output_folder}/import_year={year}/import_month={month}/import_day={day}/import_date={date}/{filename}.parquet"
    s3 = s3fs.S3FileSystem(anon=False)
    with s3.open(path, 'wb') as f:
        df.to_parquet(f)

def single_digit_to_zero_prefixed_string(value):
    return str(value) if value > 9 else '0' + str(value)


def upload_to_s3(s3_bucket_name, s3_client, file_content, file_name):
    """
    Upload file content to AWS S3.

    Args:
        s3_client (bot3.client): S3 client instance.
        file_content (bytes): File content as bytes.
        file_name (str): Name of the file in S3.

    Returns:
        None
    """
    try:
        s3_client.put_object(Bucket=s3_bucket_name, Key=file_name, Body=file_content)
        logger.info("Uploaded {file_name} to S3")
    except Exception as e:
        logger.error("Error uploading {file_name} to S3: {str(e)}")


def lambda_handler(event, context):
    # Get api api credentials from secrets manager
    #secret_name = "/data-and-insight/streets_systems_api_key"
    secret_name = getenv("API_SECRET_NAME")
    url= getenv("API_URL")
    token = ''
    s3_bucket = getenv("OUTPUT_S3_FOLDER")
    output_folder_name = getenv("TARGET_S3_BUCKET_NAME")
    landing_folder_name = getenv("LANDING_S3_FOLDER")
    crawler_raw = getenv("CRAWLER_NAME_RAW")
    output_filename = 'output'

    secrets_manager_client = boto3.client('secretsmanager')
    api_credentials_response = retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name)
    api_credentials = json.loads(api_credentials_response['SecretString'])
    username = api_credentials.get("user")
    secret = api_credentials.get("secret")


    print(f'username retrieved from secret manager: {username}')

    # accepted_classes = ['person','car','pc','head']
    locations = "all"  # <-- you can put a list of locations or just ask for 'all'

    from_s = (datetime.datetime.utcnow() - datetime.timedelta(hours=24)).strftime("%Y-%m-%d %H:00:00")
    to_s = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

    outputs = []
    # connect to API
    resp = get_data(url=url, user=username, token=token, location=locations, from_s=from_s, to_s=to_s)

    if resp.status_code != 200:
        token = refresh_token(url=url, user=username, secret=secret)
    for i in range(1):
        resp = get_data(url=url, user=username, token=token, location='all', from_s=from_s, to_s=to_s)

    resp_json = resp.json()
    print(resp_json)

    # output = filter_data(resp_json, accepted_classes=accepted_classes)
    output = resp_json

    out_df = pd.DataFrame(output)

    # comment out if you want to keep only some fields
    # out_df = out_df[['sensor_name', 'unit', 'variable', 'timestamp', 'reading']]
    out_df['dt'] = pd.to_datetime(out_df['dt'])
    out_df['dt'] = out_df['dt'].astype('datetime64[us]')
    print(out_df)

    s3_client = boto3.client('s3')

    write_dataframe_to_s3_parquet(s3_client, s3_bucket, output_folder_name, out_df, output_filename)

    # Crawl all the parquet data in S3
    glue_client = boto3.client('glue',region_name='eu-west-2')
    glue_client.start_crawler(Name=f'{crawler_raw}')


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")