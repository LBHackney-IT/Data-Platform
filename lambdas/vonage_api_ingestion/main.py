import sys

sys.path.append('./lib/')

import pandas as pd
import requests
import json

import datetime

from datetime import date
from dateutil.relativedelta import *

import time

import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
        print(f'Will call API using dates {start_date} to {end_date}')
        page = 1

        json_responses = [
            # this is a list of the responses
        ]

        print(f'Calling Page {page}')
        vonage_request = vonage_api_request(api_to_call, table_to_call, page, limit, start_date, end_date, auth_token)
        # print(vonage_request.content)

        data = vonage_request.content

        # print(f'Data being appended is of type {type(data)}')
        json_responses.append(data)

        # read metadata
        df_meta = pd.json_normalize(json.loads(vonage_request.content))

        max_pages = df_meta['meta.pageCount'][0]
        print(f'Max Pages: {max_pages}')

        while page < max_pages:
            page = page + 1
            print(f'Calling Page {page}')
            vonage_request = vonage_api_request(api_to_call, table_to_call, page, limit, start_date, end_date,
                                                auth_token)

            data = vonage_request.content
            # print(f'Data being appended is of type {type(data)}')
            json_responses.append(data)

        # checks if the correct amount of items in the list is returned
        # for each page, 1 item in the list
        if len(json_responses) == max_pages:
            data_successfully_called = True
            return json_responses # Returns all of the responses for the day, as a LIST
        else:
            print(
                f'Amount of pages in List ({len(json_responses)}) does not match the amount of pages ({max_pages}). Will try again')


def create_list_of_call_dates(start_date, end_date):

    start_call_date = date.fromisoformat(start_date)
    print(f'Date Start {str(start_call_date)}')

    end_call_date = date.fromisoformat(end_date)
    print(f'Date End {str(end_call_date)}')

    date_counter = start_call_date
    between_dates = []
    while date_counter < end_call_date:
        print(f'Date Added {str(date_counter)}')
        between_dates.append(str(date_counter))
        date_counter = date_counter + relativedelta(days=+1)
    return between_dates
    # read the dates as actual dates

def output_to_landing_zone(output_item):
    print(f'Item of type {type(output_item)}')
    print(f'Item Length {len(output_item)}')

def loop_through_dates(call_dates,auth_token):
    days_data = get_days_data(date_to_call, api_to_call, table_to_call, auth_token)

def lambda_handler():
    print("Get Auth Token")

    auth_token = get_auth_token(client_id, client_secret, scope)

    date_to_call = "2022-10-06"
    end_call_date = str(date.today())
    dates_to_call = create_list_of_call_dates(date_to_call,end_call_date)

    print(dates_to_call)

    api_to_call = "stats"
    table_to_call = "interactions"
    # days_data = get_days_data(date_to_call, api_to_call, table_to_call, auth_token)

    # print(f'Items in list of data {len(days_data)}')
    #
    # for item in days_data:
    #     output_to_landing_zone(item)

lambda_handler()