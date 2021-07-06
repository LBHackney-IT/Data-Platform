import sys
sys.path.append('./lib/')

import io
import boto3
from os import path
from os import getenv
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from oauth2client.service_account import ServiceAccountCredentials
from googleapiclient import errors
from googleapiclient import http
from dotenv import load_dotenv


def upload_file_to_s3(client, body_data, bucket_name, file_name):
    client.put_object(
        Body=body_data,
        Bucket=bucket_name,
        Key=file_name)

def download_file(service, file_id):
    request = service.files().get_media(fileId=file_id)

    file = io.BytesIO()
    downloader = MediaIoBaseDownload(file, request)
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print("Download %d%%." % int(status.progress() * 100))
    return file.getvalue()

def lambda_handler(event, lambda_context):
    load_dotenv()

    scopes = ['https://www.googleapis.com/auth/drive']

    key_file_location = path.relpath('./key_file.json')

    credentials = ServiceAccountCredentials.from_json_keyfile_name(
        key_file_location,
        scopes=scopes)

    drive_service = build(
        'drive',
        'v3',
        credentials=credentials,
        cache_discovery=False)


    file_id = getenv("FILE_ID")

    file_body = download_file(drive_service, file_id)

    bucket_name = getenv("BUCKET_ID")

    file_name = getenv("FILE_NAME")

    s3_client = boto3.client('s3')

    upload_file_to_s3(s3_client, file_body, bucket_name,file_name)

    glue_client = boto3.client('glue')

    glue_job_names = getenv("GLUE_JOB_NAMES").split("/")

    for glue_job_name in glue_job_names:
        print('Running '+ glue_job_name)
        response = glue_client.start_job_run(JobName = glue_job_name)
        print(response)


if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')
