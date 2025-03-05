import base64
import hashlib
import hmac
import json
import logging
import sys
import time
from datetime import date, datetime

import awswrangler as wr
import boto3
import pandas as pd
import requests
from awsglue.utils import getResolvedOptions
from pyathena import connect

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

arg_keys = [
    "region_name",
    "s3_endpoint",
    "s3_target_location",
    "s3_staging_location",
    "target_database",
    "target_table",
    "secret_name",
]
partition_keys = ["import_year", "import_month", "import_day", "import_date"]

args = getResolvedOptions(sys.argv, arg_keys)

region_name = args["region_name"]
s3_endpoint = args["s3_endpoint"]
s3_target_location = args["s3_target_location"]
s3_staging_location = args["s3_staging_location"]
target_database = args["target_database"]
target_table = args["target_table"]
secret_name = args["secret_name"]


def remove_illegal_characters(string):
    """Removes illegal characters from string by replacing:
    = with empty string
    / with _
    + with -
    """
    replacements = {"=": "", "/": "_", "+": "-"}

    result = string
    for old, new in replacements.items():
        result = result.replace(old, new)

    return result


def encode_json(json_string):
    """Encode JSON string"""
    json_string = json_string.encode()
    json_string = base64.b64encode(json_string)
    json_string = json_string.decode("utf-8")
    return json_string


def create_signature(header, payload, secret):
    """Encode JSON string"""
    # hashed header, hashed payload, string secret
    unsigned_token = header + "." + payload
    # secret_access_key = base64.b64decode(unsigned_token) #TODO is this used anywhere??
    key_bytes = bytes(secret, "utf-8")
    string_to_sign_bytes = bytes(unsigned_token, "utf-8")
    signature_hash = hmac.new(
        key_bytes, string_to_sign_bytes, digestmod=hashlib.sha256
    ).digest()
    encoded_signature = base64.b64encode(signature_hash)
    encoded_signature = encoded_signature.decode("utf-8")
    encoded_signature = remove_illegal_characters(encoded_signature)
    return encoded_signature


def get_token(url, encoded_header, encoded_payload, signature, headers):
    """Get token"""
    assertion = encoded_header + "." + encoded_payload + "." + signature
    data = f"assertion={assertion}&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer"
    print(f"Data : {data}")
    response = requests.request("POST", url, headers=headers, data=data)
    return response


def get_icaseworks_report_from(report_id, fromdate, auth_headers, auth_payload):
    report_url = "https://hackneyreports.icasework.com/getreport?"
    request_url = f"{report_url}ReportId={report_id}&Format=json&From={fromdate}"
    print(f"Request url: {request_url}")
    r = requests.request("GET", request_url, headers=auth_headers, data=auth_payload)
    print(f"Status Code: {r.status_code}")
    return r


def get_report_fromtime(report_id, timestamp_to_call, auth_headers, auth_payload):
    report_url = "https://hackneyreports.icasework.com/getreport?"

    now = str(datetime.now())
    timetouse = now[:19]
    print(f"TimeNow: {timetouse}")

    request_url = f"{report_url}ReportId={report_id}&Format=json&FromTime={timestamp_to_call}&UntilTime={timetouse}"
    print(f"Request url: {request_url}")
    r = requests.request("GET", request_url, headers=auth_headers, data=auth_payload)
    print(f"Status Code: {r.status_code}")
    return r


def dump_dataframe(response, location, filename):
    df = pd.DataFrame.from_dict(
        response.json(),
        orient="columns",
    )

    df["import_year"] = datetime.today().strftime("%Y")
    df["import_month"] = datetime.today().strftime("%m")
    df["import_day"] = datetime.today().strftime("%d")
    df["import_date"] = datetime.today().strftime("%Y%m%d")

    print(f"Database: {target_database}")
    print(f"Table: {target_table}")

    dict_values = ["string" for _ in range(len(df.columns))]
    dtype_dict = dict(zip(df.columns, dict_values))

    # write to s3
    wr.s3.to_parquet(
        df=df,
        path=s3_target_location,
        dataset=True,
        database=target_database,
        table=target_table,
        mode="overwrite_partitions",
        partition_cols=partition_keys,
        dtype=dtype_dict,
    )
    print(f"Dumped Dataframe {df.shape} to {s3_target_location}")
    logger.info(f"Dumped Dataframe {df.shape} to {s3_target_location}")


def get_latest_timestamp(table_dict):
    # TODO: reintroduce try except
    #   try:
    print("Getting max timestamp")
    # 2025-01-05T15:06:16

    # TODO: needs refactoring to allow for different tables
    sql_query = 'select max("casestatustouchtimes_lastupdatedtime") as latest from "data-and-insight-raw-zone"."icaseworks_foi"'

    conn = connect(s3_staging_dir=s3_staging_location, region_name=region_name)

    df = pd.read_sql_query(sql_query, conn)
    latest_date = df.iloc[0, 0]
    latest_date = latest_date.replace("T", " ")

    print("dataframe outputting")
    print(f"Time Found: {latest_date}")

    return latest_date


#   except:
#     date_to_return = "2025-01-16 00:00:00"
#     print(f'No Data Found. Will use {date_to_return}')
#     return date_to_return


def authenticate_icaseworks(api_key, secret):
    url = "https://hackney.icasework.com/token"

    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    header_object = {"alg": "HS256", "typ": "JWT"}

    # Create Header
    header_object = str(header_object).replace("'", '"').replace(" ", "")
    header = encode_json(header_object)
    print(f"Header: {header}")

    # Create payload
    current_unix_time = int(time.time())
    str_time = str(current_unix_time)
    payload_object = {"iss": api_key, "aud": url, "iat": str_time}
    payload_object = (
        str(payload_object).replace("'", '"').replace(" ", "")
    )  # can we do a dict-to-string function for this and the header

    payload = encode_json(str(payload_object))
    print(f"Created Payload: {payload}")

    # Create Signature
    signature = create_signature(header, payload, secret)
    print(f"Created Signature: {signature}")

    # Get assertion
    assertion = header + "." + payload + "." + signature
    print(f"assertion: {assertion}")

    # Get response
    response = get_token(
        url=url,
        encoded_header=header,
        encoded_payload=payload,
        signature=signature,
        headers=headers,
    )

    # Get token
    auth_token = response.json().get("access_token")

    # Create auth header for API Calls and auth payload

    authorization = f"Bearer {auth_token}"

    auth_payload = []

    auth_headers = {"Authorization": authorization}
    return auth_payload, auth_headers


def get_data(table_dict, date_to_call, auth_headers, auth_payload):
    dict_to_call = table_dict

    print(f"Pulling report for {dict_to_call['name']}")
    case_id_report_id = dict_to_call["reportid"]
    case_id_list = get_report_fromtime(
        case_id_report_id, date_to_call, auth_headers, auth_payload
    )

    dict_to_call["DF"] = (
        case_id_list  # This will append the response to the DF column in the dictionary
    )

    dump_dataframe(dict_to_call["DF"], dict_to_call["location"], date_to_call)


def get_data_from(table_dict, date_to_call, auth_headers, auth_payload):
    dict_to_call = table_dict

    print(f"Pulling report for {dict_to_call['name']}")
    case_id_report_id = dict_to_call["reportid"]
    case_id_list = get_icaseworks_report_from(
        case_id_report_id, date_to_call, auth_headers, auth_payload
    )
    # print(f'Type of case_id_list {type(case_id_list)}')

    dict_to_call["DF"] = (
        case_id_list  # This will append the response to the DF column in the dictionary
    )

    dump_dataframe(dict_to_call["DF"], dict_to_call["location"], date.today())


def retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name):
    response = secrets_manager_client.get_secret_value(
        SecretId=secret_name,
    )
    return response


def main():
    secrets_manager_client = boto3.client("secretsmanager")
    api_credentials_response = retrieve_credentials_from_secrets_manager(
        secrets_manager_client, secret_name
    )
    api_credentials = json.loads(api_credentials_response["SecretString"])
    api_key = api_credentials.get("api_key")

    secret = api_credentials.get("secret")

    auth_payload, auth_headers = authenticate_icaseworks(api_key, secret)

    list_of_datadictionaries = [
        #   {"name":"Corrective Actions", "reportid":188769, "full_ingestion":False, "location":"/content/drive/MyDrive/iCaseworks/Corrective_Actions/"},
        #   {"name":"Classifications", "reportid":188041, "full_ingestion":True, "location":"/content/drive/MyDrive/iCaseworks/classifications/"},
        {
            "name": "FOI Requests",
            "reportid": 199549,
            "full_ingestion": False,
            "location": "s3://dataplatform-stg-raw-zone/data-and-insight/icaseworks_foi/",
        }
    ]

    for data_dict in list_of_datadictionaries:
        if data_dict["full_ingestion"] is False:
            date_to_track_from = get_latest_timestamp(data_dict)
            print(f"Starting calls from {date_to_track_from}")

            get_data(data_dict, date_to_track_from, auth_headers, auth_payload)
        else:
            get_data_from(data_dict, "2020-09-01", auth_headers, auth_payload)


if __name__ == "__main__":
    main()
