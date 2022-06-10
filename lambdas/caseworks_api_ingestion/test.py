from unittest import TestCase
from unittest.mock import patch
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber
from caseworks_api_ingestion.main import get_icaseworks_report_from

BASE_URL = "https://hackneyreports.icasework.com/getreport?"

class TestCaseWorksApiIngestion(TestCase):
    @patch('caseworks_api_ingestion.main.requests.request')
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

