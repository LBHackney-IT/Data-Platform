import sys

sys.path.append('./lib/')

import requests
import json

from datetime import date
from dateutil.relativedelta import *

import time

import logging

import boto3
from dotenv import load_dotenv
from os import getenv

import re

import api_helper

# from scripts.jobs.env_context import ExecutionContextProvider, DEFAULT_MODE_AWS, LOCAL_MODE


logger = logging.getLogger()
logger.setLevel(logging.INFO)

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# from scripts.jobs.env_context import ExecutionContextProvider, DEFAULT_MODE_AWS, LOCAL_MODE

def get_auth_token(client_id, client_secret, scope):
    url = "https://emea.newvoicemedia.com/Auth/connect/token"

    grant_type = "client_credentials"

    content_type = 'application/x-www-form-urlencoded'

    headers = {
        'Content-Type': content_type
    }

    data = f"grant_type={grant_type}&client_id={client_id}&client_secret={client_secret}&scope={scope}"

    r = requests.post(url, headers=headers, data=data)
    print(f"Auth Token status Code = {r.status_code}")
    auth_token = json.loads(r.text)

    return auth_token


def vonage_api_request(api_to_call, table_to_call, page, limit, start_time, end_time, auth_token):
    url = f"https://emea.api.newvoicemedia.com/{api_to_call}/{table_to_call}?limit={str(limit)}&page={str(page)}&start={str(start_time)}&end={str(end_time)}"
    bearer = auth_token["access_token"]

    accept = "application/vnd.newvoicemedia.v3+json"
    authorization = f"Bearer {bearer}"
    # print (f"Authorization : {authorization}") # Debugging Purposes

    headers = {
        "accept": accept,
        "authorization": authorization,
    }

    payload = {}

    request_successful = False
    current_loop = 0
    max_loop = 10

    # Makes an API request, if its 200, return it. if its 504 then retry it
    while request_successful == False and current_loop <= max_loop:

        data_request = requests.request("GET", url, headers=headers, data=payload)
        if data_request.status_code == 200:
            successful_request = data_request
            request_successful = True
            return successful_request
        elif data_request.status_code == 504:
            print(
                f"Auth Token status Code: {data_request.status_code} for Date {str(start_time)}. Will wait 10 seconds and try again")
            time.sleep(10)
            current_loop = current_loop + 1
        else:
            print(f"Auth Token status Code: {data_request.status_code} for Date {str(start_time)}. Will break")
            data_request.raise_for_status()
            break


def get_days_data(date_to_call, api_to_call, table_to_call, auth_token):
    # Call all of the pages of the DAY specified
    # Day format should be datetime but I wonder if it should be made to be a string instead in case of compatibility issues
    # Do first call to get MetaData
    limit = 5000

    # parse string into date format
    start_date = date.fromisoformat(date_to_call)
    end_date = start_date + relativedelta(days=+1)

    data_successfully_called = False

    while data_successfully_called == False:
        print(f'Will call API {table_to_call} using dates {start_date} to {end_date}')
        page = 1

        json_responses = [
            # this is a list of the responses
        ]

        print(f'Calling Page {page}')
        vonage_request = vonage_api_request(api_to_call, table_to_call, page, limit, start_date, end_date, auth_token)
        # print(vonage_request.content)

        data = vonage_request.json()

        # print(f'Data being appended is of type {type(data)}')
        json_responses.append(data)

        max_pages = data['meta']['pageCount']
        print(f'Max Pages: {max_pages}')

        while page < max_pages:
            page = page + 1
            print(f'Calling Page {page}')
            vonage_request = vonage_api_request(api_to_call, table_to_call, page, limit, start_date, end_date,
                                                auth_token)

            data = vonage_request.json()
            # print(f'Data being appended is of type {type(data)}')
            json_responses.append(data)

        # checks if the correct amount of items in the list is returned
        # for each page, 1 item in the list
        if len(json_responses) == max_pages:
            data_successfully_called = True
            return json_responses  # Returns all of the responses for the day, as a LIST
        else:
            print(
                f'Amount of pages in List ({len(json_responses)}) does not match the amount of pages ({max_pages}). Will try again')


def create_list_of_call_dates(start_date, end_date):
    start_call_date = date.fromisoformat(start_date)

    start_call_date = start_call_date + relativedelta(days=+1)
    # print(f'Date Start {str(start_call_date)}')

    end_call_date = date.fromisoformat(end_date)
    # print(f'Date End {str(end_call_date)}')

    date_counter = start_call_date
    between_dates = []
    while date_counter < end_call_date:
        # print(f'Date Added {str(date_counter)}')
        between_dates.append(str(date_counter))
        date_counter = date_counter + relativedelta(days=+1)
    return between_dates
    # read the dates as actual dates


def single_digit_to_zero_prefixed_string(value):
    return str(value) if value > 9 else '0' + str(value)

def output_to_landing_zone(data, day_of_item, output_folder,s3_client,s3_bucket):
    meta = data['meta']
    page = single_digit_to_zero_prefixed_string(meta['page'])
    max_pages = single_digit_to_zero_prefixed_string(meta['pageCount'])
    print(f'Day: {day_of_item} - Meta: {meta} - Page: {page} - MaxPages: {max_pages}')

    date_of_item = date.fromisoformat(day_of_item)

    day = single_digit_to_zero_prefixed_string(date_of_item.day)
    month = single_digit_to_zero_prefixed_string(date_of_item.month)
    year = str(date_of_item.year)

    filename = f'{day_of_item}_page_{page}_of_{max_pages}'

    print(f'Begin output to S3: Filename:{filename} - Date: {date_of_item} - Page: {page}')

    print(f'Day: {day}')
    print(f'Month: {month}')
    print(f'Year: {year}')

    print(f"Outputting File to: {output_folder}/import_year={year}/import_month={month}/import_day={day}/import_date={date_of_item}/{filename}.json")
    return s3_client.put_object(
        Bucket=s3_bucket,
        Body=str(data),
        Key=f"{output_folder}/import_year={year}/import_month={month}/import_day={day}/import_date={date_of_item}/{filename}.json"
    )


def loop_through_dates(call_dates, api_to_call, table_to_call, auth_token):
    # Loop through the list of dates and make a dictionary of data. labeled by date
    compiled_data = {}
    for day_date in call_dates:
        days_data = get_days_data(day_date, api_to_call, table_to_call, auth_token)  # real code
        # days_data = f'Response for Day: {day_date}' # test code
        compiled_data[day_date] = days_data

    return compiled_data


def retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name):
    response = secrets_manager_client.get_secret_value(
        SecretId=secret_name,
    )
    return response

def export_data_dictionary(data_dict, output_location,s3_client,s3_bucket):
    looped_count = 0
    # print(f'Output Folder: {output_location}')
    # print(f'S3 Bucket: {s3_bucket}')
    for day in data_dict:
        list_count = 0
        count_of_data = len(data_dict[day])
        while list_count < count_of_data:
            output_to_landing_zone(data_dict[day][list_count], day, output_location,s3_client,s3_bucket)
            list_count = list_count + 1
            looped_count = looped_count + 1


def lambda_handler(event, lambda_context):

    #######=============== GET S3 VARIABLES ###############################
    print(f'Getting S3 Variables')
    load_dotenv()

    s3_bucket = getenv("TARGET_S3_BUCKET_NAME")
    output_folder_name = getenv("OUTPUT_FOLDER")
    glue_trigger_name = getenv("TRIGGER_NAME")
    api_to_call = getenv("API_TO_CALL")
    table_to_call = getenv("TABLE_TO_CALL")  # define in terraform

    ######################## GET SECRET VALUES ##############################
    print(f'Getting Secrets Variables')
    secret_name = getenv("SECRET_NAME")

    secrets_manager_client = boto3.client('secretsmanager')

    api_credentials_response = retrieve_credentials_from_secrets_manager(secrets_manager_client, secret_name)
    api_credentials = json.loads(api_credentials_response['SecretString'])

    client_id = api_credentials.get("api_key")
    print(f'Client_id: {client_id}')
    client_secret = api_credentials.get("secret")
    print(f'Client_secret: {client_secret}')

    ######################## Script Starts Here #############################
    print("Get Auth Token")

    scope = "stats"
    auth_token = get_auth_token(client_id, client_secret, scope)

    s3_client = boto3.client('s3')

    start_date = api_helper.get_latest_data_date(s3_client,s3_bucket,output_folder_name)
    end_call_date = str(date.today())
    dates_to_call = create_list_of_call_dates(start_date, end_call_date)

    print(f'dates_to_call = {dates_to_call}')

    called_data = loop_through_dates(dates_to_call, api_to_call, table_to_call, auth_token)

    output_location = output_folder_name
    # print(f'Output_location = {output_location}')

    export_data_dictionary(called_data, output_location,s3_client,s3_bucket)

    # check if it all outputted properly
