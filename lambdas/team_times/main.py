import os
import boto3
import requests
import csv
from datetime import datetime
import xml.etree.ElementTree as ET

s3_client = boto3.client("s3")
secrets_manager_client = boto3.client("secretsmanager")


def get_secret(secret_name, secrets_manager_client=None):
    client = secrets_manager_client or boto3.client("secretsmanager")
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except Exception as e:
        raise e
    else:
        return get_secret_value_response["SecretString"]


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
    csv_data = io.StringIO()
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


def make_api_request_and_process_data(api_endpoint, api_key, date, data_frequency, s3_client):
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


def main():
    api_endpoint = os.getenv("API_ENDPOINT")
    secret_name = os.getenv("API_SECRET_NAME")
    data_frequency = os.getenv("FREQUENCY", "D")
    api_key = get_secret(secret_name)
    date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

    make_api_request_and_process_data(api_endpoint, api_key, date, data_frequency)


if __name__ == "__main__":
    main()
