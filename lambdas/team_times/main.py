import csv
import logging
import os
import xml.etree.ElementTree as ET
from datetime import datetime
from io import StringIO

import boto3
import requests
from botocore.exceptions import ClientError

s3_client = boto3.client("s3")
ssm_client = boto3.client("ssm", region_name="eu-west-2")


def get_parameter(parameter_name, ssm_client=None):
    client = ssm_client or boto3.client("ssm", region_name="eu-west-2")
    try:
        get_parameter_response = client.get_parameter(Name=parameter_name, WithDecryption=True)
    except ClientError as e:
        logging.error(f"Failed to retrieve parameter {parameter_name}: {e}")
        return None
    else:
        return get_parameter_response.get("Parameter", {}).get("Value", None)


def save_xml_to_s3(xml_data, bucket_name, object_name, s3_client=None):
    client = s3_client or boto3.client("s3")
    client.put_object(Body=xml_data, Bucket=bucket_name, Key=object_name)
    print(f"XML saved to s3://{bucket_name}/{object_name}")


def save_csv_to_s3(csv_data, bucket_name, object_name, s3_client=None):
    client = s3_client or boto3.client("s3")
    client.put_object(Body=csv_data.getvalue(), Bucket=bucket_name, Key=object_name)
    print(f"CSV saved to s3://{bucket_name}/{object_name}")


def xml_to_csv(xml_data):
    root = ET.fromstring(xml_data)
    csv_data = StringIO()
    writer = csv.writer(csv_data)
    headers = [
        "USERID",
        "DEPARTMENT",
        "NAME",
        "SURNAME",
        "EMAIL",
        "STAFFTYPE",
        "SUBMITTED",
        "DATE",
        "OPTION1",
        "OPTION2",
        "STARTTIME",
        "STARTBREAK",
        "ENDBREAK",
        "ENDTIME",
        "OPTIONVAUE",
        "TOTALTIME",
    ]
    writer.writerow(headers)
    for employee in root.findall("Employee"):
        row = [
            employee.find(tag).text if employee.find(tag) is not None else ""
            for tag in headers
        ]
        writer.writerow(row)
    csv_data.seek(0)
    return csv_data


def make_api_request_and_process_data(
    api_endpoint, api_key, date, data_frequency, s3_client
):
    data = {"apiKey": api_key, "D": date, "E": data_frequency}
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(api_endpoint, data=data, headers=headers)
    client = s3_client or boto3.client("s3")

    if response.status_code == 200:
        print("API request successful.")
        xml_bucket_name = os.getenv("XML_BUCKET_NAME")
        xml_prefix = os.getenv("XML_PREFIX")
        csv_bucket_name = os.getenv("CSV_BUCKET_NAME")
        csv_prefix = os.getenv("CSV_PREFIX")

        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        xml_object_name = f"{xml_prefix}/timesheet_{timestamp}.xml"
        csv_object_name = f"{csv_prefix}/timesheet_{timestamp}.csv"

        save_xml_to_s3(response.text, xml_bucket_name, xml_object_name, client)

        csv_data = xml_to_csv(response.text)
        save_csv_to_s3(csv_data, csv_bucket_name, csv_object_name, client)
    else:
        print("Error:", response.status_code, response.text)


def main(event=None, context=None, s3_client=None, ssm_client=None)
    s3_client = s3_client or boto3.client("s3")
    ssm_client = ssm_client or boto3.client("ssm", region_name="eu-west-2")
    
    api_endpoint_parameter_name = os.getenv("API_ENDPOINT")
    api_secret_parameter_name = os.getenv("SECRET_NAME")
    data_frequency = os.getenv("FREQUENCY", "D")
    api_key = get_parameter(api_secret_parameter_name, ssm_client)
    api_endpoint = get_parameter(api_endpoint_parameter_name, ssm_client)
    date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

    make_api_request_and_process_data(
        api_endpoint, api_key, date, data_frequency, s3_client
    )


if __name__ == "__main__":
    main("event", "lambda_context")
