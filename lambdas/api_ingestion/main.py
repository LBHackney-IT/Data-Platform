import base64 #pybase64
import json
import hashlib
import hmac
import re #regex
import requests #
import string
import time
import pandas as pd
from dotenv import load_dotenv
import boto3

def remove_illegal_characters(string):
    """Removes illegal characters from string"""
    regex_list = [['=', ""], ['\/', "_"], ['+', "-"]]
    for r in regex_list:
        clean_string = re.sub(string=string,
                       pattern="[{}]".format(r[0]),
                       repl=r[1])
    return clean_string


def encode_json(json_string):
    """Encode JSON string"""
    json_string = json_string.encode()
    json_string = base64.b64encode(json_string)
    json_string = json_string.decode("utf-8")
    return json_string


def create_signature(header, payload, secret):
    """Encode JSON string"""
    # hashed header, hashed payload, string secret
    unsigned_token = header + '.' + payload
    # secret_access_key = base64.b64decode(unsigned_token) #TODO is this used anywhere??
    key_bytes = bytes(secret, 'utf-8')
    string_to_sign_bytes = bytes(unsigned_token, 'utf-8')
    signature_hash = hmac.new(key_bytes, string_to_sign_bytes, digestmod=hashlib.sha256).digest()
    encoded_signature = base64.b64encode(signature_hash)
    encoded_signature = encoded_signature.decode('utf-8')
    encoded_signature = remove_illegal_characters(encoded_signature)
    return encoded_signature


def get_token(url, encoded_header, encoded_payload, signature, headers):
    """Get token"""
    assertion = encoded_header + "." + encoded_payload + "." + signature
    data = f'assertion={assertion}&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'
    print(f'Data : {data}')
    response = requests.request("POST", url, headers=headers, data=data)
    return response


def get_icaseworks_report_from (report_id,fromdate,auth_headers,auth_payload):
    report_url = "https://hackneyreports.icasework.com/getreport?"
    request_url = f'{report_url}ReportId={report_id}&Format=json&From={fromdate}'
    print(f'Request url: {request_url}')
    response = requests.request("GET", request_url, headers=auth_headers, data=auth_payload)
    print(f'Status Code: {r.status_code}')
    return response.get("content")

# def get_icaseworks_report_day (report_id, auth_headers, date_to_call):
#   report_url = "https://hackneyreports.icasework.com/getreport?"
#   request_url = f'{report_url}ReportId={report_id}&Format=xml&From={date_to_call}&Until={date_to_call}'
#   print(f'Request url: {request_url}')
#   r = requests.request("GET", request_url, headers=auth_headers, data=auth_payload)
#   print(f'Status Code: {r.status_code}')
#   return r

def write_dataframe_to_s3(data, s3_bucket, output_folder, filename):
    s3_client = boto3.client('s3')
    s3_client.put_object(
        Bucket=s3_bucket,
        Body=data
        Key=f"${output_folder}/${filename}"
    )


def lambda_handler(event, lambda_context):
    load_dotenv()
    s3_bucket = getenv("TARGET_S3_BUCKET_NAME")
    output_folder_name = getenv("OUTPUT_FOLDER")
    url = "https://hackney.icasework.com/token"

    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    api_key = getenv("API_KEY")
    secret = getenv("SECRET")
    header_object = {"alg":"HS256","typ":"JWT"}

    # Create Header
    header_object = str(header_object).replace("'", '"').replace(" ", "") # can we format this when we declare as a variable instead?
    header = encode_json(header_object)
    print(f'Header: {header}')

    # Create payload
    current_unix_time = int(time.time())
    str_time = str(current_unix_time)
    payload_object = {
        "iss" : api_key,
        "aud" : url,
        "iat" : str_time
    }
    payload_object = str(payload_object).replace("'", '"').replace(" ", "") # can we do a dict-to-string function for this and the header

    payload = encode_json(str(payload_object))
    print(f'Created Payload: {payload}')

    # Create Signature
    signature = create_signature(header, payload, secret)
    print(f'Created Signature: {signature}')

    # Get assertion
    assertion = header + "." + payload + "." + signature
    print(f'assertion: {assertion}')

    # Get response
    response = get_token(url=url, encoded_header=header, encoded_payload=payload, signature=signature, headers=headers)
    print(response)

    # Get token
    auth_token = response.json().get('access_token')
    print(f'auth token: {auth_token}')

    # Create auth header for API Calls and auth payload
    authorization = f'Bearer {auth_token}'
    print(authorization)

    auth_payload = {}

    # Note: I don't know how to generate the below cookie. That is extracted using postman. Not sure how to recreate this at all
    auth_headers = {
        'Authorization': authorization,
    }

    report_tables = [
    # {"name":"Time Spent for Cases Received", "id":122641},
    # {"name":"Tasks Created", "id":122543},
    # {"name":"ServicesResponsible for Delay", "id":122541},
    # {"name":"Correspondence Created", "id":122642},
    # {"name":"Corrective Actions", "id":122443},
    # {"name":"Compensation", "id":122442},
    # {"name":"Case Contacts", "id":122542},
    {"name":"Cases received", "id":122109}
    ]

    date_to_track_from = "2019-01-01"

    for report_details in report_tables:
        print(f'Pulling report for {report_details["name"]}')
        case_id_report_id = report_details["id"]
        case_id_list = get_icaseworks_report_from(case_id_report_id,date_to_track_from,auth_headers,auth_payload)
        report_details["data"] = case_id_list
        # write to s3
        write_dataframe_to_s3(report_details["data"], s3_bucket, output_folder_name, report_details["name"])

if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')