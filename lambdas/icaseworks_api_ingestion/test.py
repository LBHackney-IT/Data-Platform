from unittest import TestCase
from unittest.mock import patch
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber
from datetime import datetime
from icaseworks_api_ingestion.main import get_icaseworks_report_from, get_token, encode_string, remove_illegal_characters, write_dataframe_to_s3, dictionary_to_string, retrieve_credentials_from_secrets_manager, single_digit_to_zero_prefixed_string, start_glue_trigger
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

        auth_token = {"access_token": "test123", "token_type": "Bearer", "expires_in": 3600}
        response_object = MockResponse(auth_token, 200)
        post_requests_mock.return_value = response_object

        response = get_token(url=url, encoded_header=header, encoded_payload=payload, signature=signature, headers=headers)

        self.assertEqual("test123", response)
        post_requests_mock.assert_called_with(url, headers=headers, data=data)

    def test_retrieve_credentials_from_secrets_manager(self):
        self.secrets_boto_session = botocore.session.get_session()
        self.secrets_boto_session.set_credentials("", "")
        self.secrets_manager = self.secrets_boto_session.create_client('secretsmanager', region_name='eu-west-2')
        self.stubber = Stubber(self.secrets_manager)

        secret_name = "random_secret_name"

        expected_params = {
            'SecretId': secret_name
        }

        response = {
            'ARN': 'arn:aws:secretsmanager:eu-west-2:111111111:secret:secret-key',
            'Name': 'string',
            'VersionId': 'version_one_secret_name_11111111:version_one',
            'SecretBinary': b'bytes',
            'SecretString': 'string',
            'VersionStages': [
                'string',
            ],
            'CreatedDate': datetime(2015, 1, 1)
        }

        self.stubber.add_response('get_secret_value', response, expected_params)
        self.stubber.activate()

        service_response = retrieve_credentials_from_secrets_manager(self.secrets_manager, secret_name)
        self.assertEqual(service_response, response)

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

    def test_write_dataframe_to_s3(self):
        self.boto_session = botocore.session.get_session()
        self.boto_session.set_credentials("", "")
        self.s3 = self.boto_session.create_client('s3')
        self.stubber = Stubber(self.s3)

        bucket = 'landing-zone'
        filename = "caseworks-file"
        output_folder = "caseworks"
        current_date = datetime.now()
        day = single_digit_to_zero_prefixed_string(current_date.day)
        month = single_digit_to_zero_prefixed_string(current_date.month)
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
        self.assertEqual(service_response, response)

    def test_single_digit_to_zero_prefixed_string_prefixes_single_digit_with_zero(self):
        result_with_zero_prefix = single_digit_to_zero_prefixed_string(9)
        self.assertEqual(result_with_zero_prefix, "09")

    def test_single_digit_to_zero_prefixed_does_not_prefix_double_digits_with_zero(self):
        result_without_zero_prefix = single_digit_to_zero_prefixed_string(10)
        self.assertEqual(result_without_zero_prefix, "10")

    def test_correct_glue_trigger_is_started_after_data_ingestion(self):
        trigger_name = "glue-trigger-name" 
       
        expected_params = {
            'Name': trigger_name
        }

        self.boto_session = botocore.session.get_session()
        self.boto_session.set_credentials("", "")
        self.glue = self.boto_session.create_client('glue', region_name='any-region')
        self.glueStubber = Stubber(self.glue)        
        self.glueStubber.add_response('start_trigger', {}, expected_params)
        self.glueStubber.activate()
        
        start_glue_trigger(self.glue, trigger_name)

        self.glueStubber.assert_no_pending_responses()
