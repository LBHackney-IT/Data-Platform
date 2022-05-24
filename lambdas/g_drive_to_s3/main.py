import sys
sys.path.append('./lib/')

import io
import boto3
import json
from os import path, getenv, mkdir, listdir, rmdir, remove
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
    request = service.files().get_media(fileId=file_id, supportsAllDrives=True)

    file = io.BytesIO()
    downloader = MediaIoBaseDownload(file, request)
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print("Download %d%%." % int(status.progress() * 100))
    return file.getvalue()

def directory_exists(directory_path):
    return path.isdir(directory_path)

def lambda_handler(event, lambda_context):
    load_dotenv()

    google_service_account_credentials_secret_arn = getenv("GOOGLE_SERVICE_ACCOUNT_CREDENTIALS_SECRET_ARN")

    print(f"secrets arn: {google_service_account_credentials_secret_arn}")

    secrets_manager_client = boto3.client('secretsmanager')

    service_account_secret = secrets_manager_client.get_secret_value(
      SecretId=google_service_account_credentials_secret_arn
    )

    secret = service_account_secret['SecretBinary']
    secret_dict = json.loads(secret)

    tmp_directory = "/tmp/lambda"

    if directory_exists(tmp_directory):
      for file in listdir(tmp_directory):
        remove(path.join(tmp_directory, file))
      rmdir(tmp_directory)

    mkdir(tmp_directory)

    json_file = open(f"{tmp_directory}/key_file.json", "w")
    json.dump(secret_dict, json_file, indent="")
    json_file.close()

    key_file_location = path.relpath(f"{tmp_directory}/key_file.json")

    scopes = [
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive',
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.metadata'
    ]

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

    workflow_names = getenv("WORKFLOW_NAMES").split("/")

    for workflow_name in workflow_names:
        try:
            response = glue_client.start_workflow_run(Name = workflow_name)
        except Exception as e:
            print('Failed to run '+ workflow_name)
            print(e)

if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')
