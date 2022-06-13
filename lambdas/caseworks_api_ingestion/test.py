from unittest import TestCase
from unittest.mock import patch
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber
from caseworks_api_ingestion.main import get_icaseworks_report_from, get_token

BASE_URL = "https://hackneyreports.icasework.com/getreport?"

class TestCaseWorksApiIngestion(TestCase):
    @patch('caseworks_api_ingestion.main.requests.get')
    def test_get_icaseworks_report_from(self, get_requests_mock):
        report_id = "123"
        from_date = "2019-01-01"
        auth_headers = {
            'Authorization': "Bearer token"
        }
        auth_payload = "123xkcjd"

        content = '[{"data": "test"}]'.encode()

        get_requests_mock.return_value.content = content

        response = get_icaseworks_report_from(report_id, from_date, auth_headers, auth_payload)

        self.assertEqual(response, content)
        request_url = f"{BASE_URL}ReportId={report_id}&Format=json&From={from_date}"
        get_requests_mock.assert_called_with("GET", request_url, headers=auth_headers, data=auth_payload)


    @patch('caseworks_api_ingestion.main.requests.request')
    def test_get_token(self, post_requests_mock):
        url = "https://example-url.com/token"
        header = '[{{"encoded": "header"}}]'
        payload = '[{{"encoded": "payload"}}]'
        signature = "12dksafi1"
        headers = {
            'Content-Type': 'app/urlencoded',
        }

        auth_token = "6dhfakkaT1O2K3E4N6d5ea"
        post_requests_mock.return_value = auth_token

        response = get_token(url=url, encoded_header=header, encoded_payload=payload, signature=signature, headers=headers)
        self.assertEqual(response, content)
        # assert it gets called with correct params like above test






# test get_token url
# test encode_json
# test remove_illegal_characters
# skip create_signature but mock in full end to end test
# test write_dataframe_to_s3 - see g drive for stub methods
