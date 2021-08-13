import sys

sys.path.append('./lib/')

import io
import boto3
from os import path
from os import getenv
from dotenv import load_dotenv
import json

import base64
from datetime import datetime, timedelta
import hmac, hashlib
import requests


class APIClass:
    def __init__(self, public_key, private_key, data=None, debug=False):
        the_time = datetime.now() + timedelta(hours=1)
        the_time = the_time.strftime('%Y%m%d%H%M')
        the_time = the_time.encode('utf-8')
        crypt = hashlib.sha256(public_key + the_time)
        token = crypt.hexdigest().encode('utf-8')
        hash = base64.b64encode(hmac.new(private_key, token, hashlib.sha256).hexdigest().encode('utf-8'))
        self.token = token
        self.public_key = public_key
        self.private_key = private_key
        self.hash = hash
        self.debug = debug
        self.data = data

    def sendRequest(self, request_uri, request_method):

        headers = {'X-Public': self.public_key, 'X-Hash': self.hash, 'X-Debug': str(self.debug)}
        payload = self.data

        if request_method == 'GET':
            r = requests.get(request_uri, params=payload, headers=headers)
        elif request_method == 'POST':
            r = requests.post(request_uri, params=payload, headers=headers)
        elif request_method == 'PUT':
            r = requests.put(request_uri, params=payload, headers=headers)
        elif request_method == 'DELETE':
            r = requests.delete(request_uri, params=payload, headers=headers)

        if r.status_code == 200:
            print(f'Status code less than 400: {r.ok}, Status code: {r.status_code},  {r.headers}')
            # return JSON
            return r.json(), r.headers
        else:
            print(f'Status code: {r.status_code}. JSON: {r.json()}, {r.headers}')


def upload_file_to_s3(client, body_data, bucket_name, file_name):
    client.put_object(
        Body=body_data,
        Bucket=bucket_name,
        Key=file_name)


def lambda_handler(event, lambda_context):
    load_dotenv()

    public_key = getenv("PUBLIC_KEY")
    public_key = public_key.encode('utf-8')
    private_key = getenv("PRIVATE_KEY")
    private_key = private_key.encode('utf-8')
    resource = getenv("RESOURCE")
    request_uri = f'https://hackney-planning.tascomi.com/rest/v1/{resource}'
    request_method = 'GET'
    bucket_name = getenv("BUCKET_ID")
    s3_client = boto3.client('s3')

    newClass = APIClass(public_key, private_key,data=None, debug=True)
    data, headers = newClass.sendRequest(request_uri=request_uri, request_method=request_method)

    for i, json_body in enumerate(data):
        upload_file_to_s3(
            s3_client,
            json.dumps(json_body),
            bucket_name,
            f'tascomi/{resource}_json/1_{i}.json'
        )

    num_results = int(headers.get('X-Number-Of-Results'))
    print('num_results', num_results)
    page_num = int(headers.get('X-Page-Number'))
    print('page_num', page_num)
    results_per_page = int(headers.get('X-Results-Per-Page'))
    print('results_per_page', results_per_page)
    number_of_pages = round(num_results/results_per_page)
    print('number_of_pages', number_of_pages)
    while page_num <= number_of_pages:
        page_num += 1
        i_data, i_headers = newClass.sendRequest(request_uri=f'{request_uri}?page={page_num}', request_method=request_method)
        for i, json_body in enumerate(i_data):
            upload_file_to_s3(
                s3_client,
                json.dumps(json_body),
                bucket_name,
                f'tascomi/{resource}_json/{page_num}_{i}.json'
            )

    glue_client = boto3.client('glue')

    workflow_names = getenv("WORKFLOW_NAMES").split("/")

    for workflow_name in workflow_names:
        try:
            response = glue_client.start_workflow_run(Name=workflow_name)
        except Exception as e:
            print('Failed to run ' + workflow_name)
            print(e)


if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')
