import datetime
import hashlib
import hmac
import json
import logging
import re
import sys
import time
from os import getenv

import boto3
import pybase64
import requests
from dotenv import load_dotenv


sys.path.append("./lib/")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def remove_illegal_characters(string):
    """Removes illegal characters from string"""
    regex_list = [["=", ""], ["\/", "_"], ["+", "-"]]
    for r in regex_list:
        string = re.sub(string=string, pattern="[{}]".format(r[0]), repl=r[1])
    return string


def encode_string(string):
    """Encode JSON string"""
    byte_string = string.encode()
    base64_encoded_string = pybase64.b64encode(byte_string)
    processed_string = base64_encoded_string.decode("utf-8")
    return processed_string


def dictionary_to_string(dictionary):
    return str(dictionary).replace("'", '"').replace(" ", "")


def create_signature(header, payload, secret):
    """Encode JSON string"""
    # hashed header, hashed payload, string secret
    unsigned_token = header + "." + payload
    key_bytes = bytes(secret, "utf-8")
    string_to_sign_bytes = bytes(unsigned_token, "utf-8")
    signature_hash = hmac.new(
        key_bytes, string_to_sign_bytes, digestmod=hashlib.sha256
    ).digest()
    encoded_signature = pybase64.b64encode(signature_hash)
    encoded_signature = encoded_signature.decode("utf-8")
    encoded_signature = remove_illegal_characters(encoded_signature)
    return encoded_signature


def get_token(url, encoded_header, encoded_payload, signature, headers):
    """Get token"""
    assertion = encoded_header + "." + encoded_payload + "." + signature
    data = f"assertion={assertion}&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer"
    response = requests.post(url, headers=headers, data=data)
    response_json = response.json()
    auth_token = response_json.get("access_token")
    return auth_token


def get_icaseworks_report_from(report_id, from_date, auth_headers, auth_payload):
    report_url = "https://hackneyreports.icasework.com/getreport?"
    request_url = f"{report_url}ReportId={report_id}&Format=json&From={from_date}"
    logger.info(f"Request url: {request_url}")
    response = requests.get(request_url, headers=auth_headers, data=auth_payload)
    logger.info(f"Status Code: {response.status_code}")
    return response.content


def write_dataframe_to_s3(s3_client, data, s3_bucket, output_folder, filename):
    filename = re.sub("[^a-zA-Z0-9]+", "-", filename).lower()
    current_date = datetime.datetime.now()
    day = single_digit_to_zero_prefixed_string(current_date.day)
    month = single_digit_to_zero_prefixed_string(current_date.month)
    year = str(current_date.year)
    date = year + month + day
    return s3_client.put_object(
        Bucket=s3_bucket,
        Body=data,
        Key=f"{output_folder}/import_year={year}/import_month={month}/import_day={day}/import_date={date}/{filename}.json",
    )


def retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name):
    response = secrets_manager_client.get_secret_value(
        SecretId=secret_name,
    )
    return response


def lambda_handler(event, lambda_context):
    load_dotenv()
    s3_bucket = getenv("TARGET_S3_BUCKET_NAME")
    output_folder_name = getenv("OUTPUT_FOLDER")
    glue_trigger_name = getenv("TRIGGER_NAME")
    url = "https://hackney.icasework.com/token"

    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
    }

    # Get api api credentials from secrets manager
    secret_name = getenv("SECRET_NAME")
    secrets_manager_client = boto3.client("secretsmanager")
    api_credentials_response = retrieve_credentials_from_secrets_manager(
        secrets_manager_client, secret_name
    )
    api_credentials = json.loads(api_credentials_response["SecretString"])
    api_key = api_credentials.get("api_key")
    secret = api_credentials.get("secret")

    header_object = {"alg": "HS256", "typ": "JWT"}

    # Create Header
    header_object = dictionary_to_string(header_object)
    header = encode_string(header_object)

    # Create payload
    current_unix_time = int(time.time())
    str_time = str(current_unix_time)
    payload_object = {"iss": api_key, "aud": url, "iat": str_time}

    payload_object = dictionary_to_string(payload_object)

    payload = encode_string(payload_object)

    # Create Signature
    signature = create_signature(header, payload, secret)

    # Get token from response
    auth_token = get_token(
        url=url,
        encoded_header=header,
        encoded_payload=payload,
        signature=signature,
        headers=headers,
    )

    # Create auth header for API Calls and auth payload
    authorization = f"Bearer {auth_token}"

    auth_payload = {}

    auth_headers = {
        "Authorization": authorization,
    }

    report_tables = [
        # {"name":"Time Spent for Cases Received", "id":122641},
        # {"name":"Tasks Created", "id":122543},
        # {"name":"ServicesResponsible for Delay", "id":122541},
        # {"name":"Correspondence Created", "id":122642},
        # {"name":"Corrective Actions", "id":122443},
        # {"name":"Compensation", "id":122442},
        # {"name":"Case Contacts", "id":122542},
        {"name": "Cases received", "id": 122109}
    ]

    today = datetime.datetime.utcnow().date()
    # Take only yesterday's data
    date_to_track_from = today - datetime.timedelta(days=1)
    logger.info(f"Date to track from: {date_to_track_from}")

    s3_client = boto3.client("s3")

    for report_details in report_tables:
        logger.info(f"Pulling report for {report_details['name']}")
        case_id_report_id = report_details["id"]
        case_id_list = get_icaseworks_report_from(
            case_id_report_id, date_to_track_from, auth_headers, auth_payload
        )
        report_details["data"] = case_id_list
        write_dataframe_to_s3(
            s3_client,
            report_details["data"],
            s3_bucket,
            output_folder_name,
            report_details["name"],
        )
        logger.info(f"Finished writing report for {report_details['name']} to S3")

    # Trigger glue job to copy from landing to raw and convert to parquet
    glue_client = boto3.client("glue")
    start_glue_trigger(glue_client, glue_trigger_name)


def single_digit_to_zero_prefixed_string(value):
    return str(value) if value > 9 else "0" + str(value)


def start_glue_trigger(glue_client, trigger_name):
    trigger_details = glue_client.start_trigger(Name=trigger_name)
    logger.info(f"Started trigger: {trigger_details}")
