import sys
sys.path.append('./lib/')

import os
import io
import csv
import json
import logging
import boto3
from botocore.exceptions import NoCredentialsError
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from google.auth.transport.requests import Request

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Define the MIME types for Google Sheets, JSON, and CSV files
mime_types = [
    'application/vnd.google-apps.spreadsheet',  # Google Sheets
    'application/json',  # JSON files
    'text/csv',  # CSV files (text/csv MIME type)    
    # 'application/vnd.ms-excel',  # CSV files (Microsoft Excel)
]


def get_secret(secret_name):
    """
    Retrieve a secret from AWS Secrets Manager.

    Args:
        secret_name (str): The name of the secret to retrieve.

    Returns:
        str or dict: The value of the secret, either as a string or a dictionary.
    """
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    secret_data = response.get('SecretString')

    try:
        secret_dict = json.loads(secret_data)
        return secret_dict
    except json.JSONDecodeError:
        return secret_data


def authenticate_google_drive(google_credentials):
    """
    Authenticate using Google Drive service account credentials.

    Args:
        google_credentials (dict): Google Drive API credentials as a dictionary.

    """
    creds = None
    SCOPES = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets']

    if google_credentials:
        creds = service_account.Credentials.from_service_account_info(
            google_credentials, scopes=SCOPES)
        creds.refresh(Request())
    else:
        logger.error('Google Drive credentials not found in Secrets Manager.')
        return None
    return creds


def initialize_s3_client():
    """
    Initialize and return an AWS S3 client using default credentials.

    Returns:
        bot3.client: S3 client instance.
    """
    return boto3.client('s3')


def export_google_sheets(service, file_id):
    """
    Export Google Sheets file to CSV format.

    Args:
        service (googleapiclient.discovery.Resource): Google Drive service instance.
        file_id (str): ID of the Google Sheets file to export.

    Returns:
        bytes: Exported CSV file content as bytes.
    """
    request = service.files().export_media(fileId=file_id, mimeType='text/csv')
    exported_csv = io.BytesIO()
    downloader = MediaIoBaseDownload(exported_csv, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    return exported_csv.getvalue()


def download_file(service, file_id, mime_type):
    """
    Download file content from Google Drive.

    Args:
        service (googleapiclient.discovery.Resource): Google Drive service instance.
        file_id (str): ID of the file to download.
        mime_type (str): MIME type of the file.

    Returns:
        bytes: File content as bytes.
    """
    if mime_type == 'application/vnd.google-apps.spreadsheet':
        # For Google Sheets, export to CSV first
        return export_google_sheets(service, file_id)
    elif mime_type == 'application/json' or mime_type == 'text/csv':
        # For other file types, directly download
        request = service.files().get_media(fileId=file_id)
        downloaded_file = io.BytesIO()
        downloader = MediaIoBaseDownload(downloaded_file, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()
        return downloaded_file.getvalue()


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
        logger.info(f"Uploaded {file_name} to S3")
    except Exception as e:
        logger.error(f"Error uploading {file_name} to S3: {str(e)}")


def lambda_handler(event, context):
    """
    Lambda function to synchronize files from a Google Drive folder to an S3 bucket.
    
    Parameters:
    - event: The AWS Lambda event object.
    - context: The AWS Lambda context object.
    
    This function retrieves necessary credentials and configuration information from AWS Secrets Manager
    and then uses these credentials to authenticate with Google Drive and S3. It lists the content of
    a specific Google Drive folder and synchronizes the files found in that folder with an S3 bucket.
    
    If any errors occur during the synchronization process, they are logged.
    
    Returns:
    None
    """
    secrets = get_secret("test-data-ingestion")
    
    google_drive_folder_id = secrets.get('GOOGLE_DRIVE_FOLDER_ID')
    s3_bucket_name = secrets.get('S3_BUCKET_NAME')
    google_credentials = json.loads(secrets.get('google_credentials'))

    if not google_drive_folder_id or not s3_bucket_name or not google_credentials:
        logger.error('Google Drive folder ID, S3 bucket name, or Google Drive credentials not found in Secrets Manager.')
        return

    google_drive_credentials = authenticate_google_drive(google_credentials)
    if not google_drive_credentials:
        return

    drive_service = build('drive', 'v3', credentials=google_drive_credentials)
    s3_client = initialize_s3_client()

    # List the content of the Google Drive folder
    results = drive_service.files().list(
        q=f"'{google_drive_folder_id}' in parents",
        fields="nextPageToken, files(id, name, mimeType)"
    ).execute()

    items = results.get('files', [])

    if not items:
        logger.info('No matching files found in the folder.')
    else:
        for item in items:
            file_name = item['name']
            file_id = item['id']
            mime_type = item['mimeType']
            
            try:
                if mime_type in mime_types:
                    
                    # Download the file content from Google Drive
                    file_content = download_file(drive_service, file_id, mime_type)
                    
                    if mime_type == 'application/vnd.google-apps.spreadsheet':
                        file_name = f"{file_name}.csv"
                    
                    # Upload the file to S3
                    upload_to_s3(s3_bucket_name, s3_client, file_content, file_name)
                
            except Exception as e:
                logger.error(f"Error processing {file_name}: {str(e)}")

if __name__ == '__main__':
    lambda_handler("event", "context")
