# from google.oauth2 import service_account
from os import path
import io
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
from oauth2client.service_account import ServiceAccountCredentials
from googleapiclient import errors
from googleapiclient import http
import boto3

def upload_file_to_s3(client, body_data, bucket, file_name):
    client.put_object(
        Body=body_data,
        Bucket='my_bucket_name',
        Key='my/key/including/anotherfilename.txt')

def download_file(service, file_id):
    request = service.files().get_media(fileId=file_id)

    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print("Download %d%%." % int(status.progress() * 100))
    return fh.getvalue()

def main():
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

    s3_client = boto3.client('s3')

    file_id = '1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq'

    file_body = download_file(drive_service, file_id)

    # f = open("demofile2.xlsx", "wb")
    # f.write(file_body)
    # f.close()
    upload_file_to_s3(s3_client, file_body, 'bucket', 'file_name')


if __name__ == '__main__':
    main()
