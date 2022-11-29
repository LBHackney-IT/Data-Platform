from unittest import TestCase
from unittest.mock import patch
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber
from datetime import datetime
from  vonage_api_ingestion.main import create_list_of_call_dates

class TestVonageApiIngestion(TestCase):

    def test_create_list_of_call_dates(self):
        input_start_date = "2021-10-03"
        input_end_date = "2021-10-05"

        expected = ["2021-10-04"]

        actual = create_list_of_call_dates(input_start_date,input_end_date)

        self.assertEqual(expected, actual, f"expected: {expected} but got: {actual}")

    def test_create_list_of_call_dates2(self):
        input_start_date = "2021-01-01"
        input_end_date = "2021-02-01"

        expected = ["2021-01-02",
                    "2021-01-03",
                    "2021-01-04",
                    "2021-01-05",
                    "2021-01-06",
                    "2021-01-07",
                    "2021-01-08",
                    "2021-01-09",
                    "2021-01-10",
                    "2021-01-11",
                    "2021-01-12",
                    "2021-01-13",
                    "2021-01-14",
                    "2021-01-15",
                    "2021-01-16",
                    "2021-01-17",
                    "2021-01-18",
                    "2021-01-19",
                    "2021-01-20",
                    "2021-01-21",
                    "2021-01-22",
                    "2021-01-23",
                    "2021-01-24",
                    "2021-01-25",
                    "2021-01-26",
                    "2021-01-27",
                    "2021-01-28",
                    "2021-01-29",
                    "2021-01-30",
                    "2021-01-31",
                    ]

        actual = create_list_of_call_dates(input_start_date,input_end_date)

        self.assertEqual(expected, actual, f"expected: {expected} but got: {actual}")
