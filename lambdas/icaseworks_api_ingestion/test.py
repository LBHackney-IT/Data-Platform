from unittest import TestCase
from unittest.mock import patch
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber
from datetime import datetime
from icaseworks_api_ingestion.main import get_icaseworks_report_from, get_token, encode_string, remove_illegal_characters, write_dataframe_to_s3, dictionary_to_string, retrieve_credentials_from_secrets_manager
from icaseworks_api_ingestion.helpers import MockResponse

BASE_URL = "https://hackneyreports.icasework.com/getreport?"

class TestCaseWorksApiIngestion(TestCase):
    @patch('icaseworks_api_ingestion.main.requests.get')
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
        get_requests_mock.assert_called_with(request_url, headers=auth_headers, data=auth_payload)


    @patch('icaseworks_api_ingestion.main.requests.post')
    def test_get_token(self, post_requests_mock):
        url = "https://example-url.com/token"
        header = '[{{"encoded": "header"}}]'
        payload = '[{{"encoded": "payload"}}]'
        signature = "12dksafi1"
        headers = {
            'Content-Type': 'app/urlencoded',
        }
        assertion = header + "." + payload + "." + signature
        data = f'assertion={assertion}&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'

        auth_token = {"access_token": "fake_token6dhfakkaT1O2K3E4N6d5ea", "token_type": "Bearer", "expires_in": 3600}
        response_object = MockResponse(auth_token, 200)
        post_requests_mock.return_value = response_object

        response = get_token(url=url, encoded_header=header, encoded_payload=payload, signature=signature, headers=headers)

        self.assertEqual("fake_token6dhfakkaT1O2K3E4N6d5ea", response)
        post_requests_mock.assert_called_with(url, headers=headers, data=data)


    def test_dictionary_to_string(self):
        expected = '{"iss":"this","aud":"https://url.com","iat":"time"}'
        dictionary = {"iss" : "this", "aud": "https://url.com", "iat": "time"}

        actual = dictionary_to_string(dictionary)

        self.assertEqual(expected, actual)


    def test_encode_string(self):
        string = "Hello world"

        expected = "SGVsbG8gd29ybGQ="
        actual = encode_string(string)

        self.assertEqual(expected, actual)


    def test_remove_illegal_characters(self):
        illegal_char_string = "_123=c/bc+"

        expected = "_123c_bc-"
        actual = remove_illegal_characters(illegal_char_string)

        self.assertEqual(expected, actual, f"expected: {expected} but got: {actual}")


    def setUp(self) -> None:
        self.boto_session = botocore.session.get_session()
        self.boto_session.set_credentials("", "")
        self.s3 = self.boto_session.create_client('s3')
        self.stubber = Stubber(self.s3)
        return super().setUp()


    def test_write_dataframe_to_s3(self):
        bucket = 'landing-zone'
        filename = "caseworks-file"
        output_folder = "caseworks"
        current_date = datetime.now()
        day = str(current_date.day) if current_date.day > 10 else '0' + str(current_date.day)
        month = str(current_date.month) if current_date.month > 10 else '0' + str(current_date.month)
        year = str(current_date.year)
        date = year + month + day

        key = f"{output_folder}/import_year={year}/import_month={month}/import_day={day}/import_date={date}/{filename}.json"
        data = '[{"data": "test"}]'

        expected_params = {
            'Bucket': bucket,
            'Body': data,
            'Key': key
        }

        response = {
            'Expiration': 'random',
            'ETag': '12345',
            'VersionId': '1.0'
        }

        self.stubber.add_response('put_object', response, expected_params)
        self.stubber.activate()

        service_response = write_dataframe_to_s3(self.s3, data, bucket, output_folder, filename)
        print(f"service response: {service_response}")
        self.assertEqual(service_response, response)
