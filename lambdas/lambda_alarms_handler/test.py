from unittest import TestCase, mock
from main import lambda_handler, format_message
import os
import botocore.session
from botocore.stub import Stubber
from datetime import datetime
from json import dumps

class TestLambdaAlarmsHandler(TestCase):
    
    mock_env_vars = {"SECRET_NAME": "test_secret_name"}

    def setUp(self):
        self.boto_session = botocore.session.get_session()
        self.boto_session.set_credentials("", "")
        self.secretsmanager_client = self.boto_session.create_client('secretsmanager', region_name='test-region-2')
        self.secretsmanager_client_stubber = Stubber(self.secretsmanager_client)

        self.secret = 'secret_string_abc'

        self.response = {
            'ARN': 'arn:aws:secretsmanager:eu-west-2:111111111:secret:secret-key',
            'Name': 'string',
            'VersionId': 'version_one_secret_name_11111111:version_one',
            'SecretBinary': b'bytes',
            'SecretString': self.secret,
            'VersionStages': [
                'string',
            ],
            'CreatedDate': datetime(2022, 1, 1)
        }

        self.sns_event = {
            "Records": [
                {
                "EventVersion": "1.0", 
                "EventSubscriptionArn": "arn:aws:sns:lambda-failure", 
                "EventSource": "aws:sns", 
                "Sns": {
                    "Signature": "EXAMPLE", 
                    "MessageId": "108e2d6c-34a8-50ef-a9b6-716bd21412d2", 
                    "Type": "Notification", 
                    "TopicArn": "arn:aws:sns:laambda-failure-notification", 
                    "MessageAttributes": {}, 
                    "SignatureVersion": "1", 
                    "Timestamp": "2015-06-03T17:43:27.123Z", 
                    "SigningCertUrl": "EXAMPLE", 
                    "Message": "Sample alert", 
                    "UnsubscribeUrl": "EXAMPLE", 
                    "Subject": "LambdaAlarm"
                }
                }
            ]
        }

        self.secret_name = "test_secret_name"       

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch('urllib3.PoolManager', spec=True)
    def test_calls_get_secret_value_on_secret_manager_client_with_correct_secret_name(self, mock_urllib_poolmanager):
        expected_params = {'SecretId': self.secret_name}
        self.secretsmanager_client_stubber.add_response('get_secret_value', self.response, expected_params)
        self.secretsmanager_client_stubber.activate()
       
        lambda_handler(event=self.sns_event, secretsManagerClient=self.secretsmanager_client)
        
        self.secretsmanager_client_stubber.assert_no_pending_responses()
    
    def test_format_message_creates_a_message_in_correct_format_based_on_sns_event_content(self):
        expected_message = {
            'text': "2015-06-03T17:43:27.123Z Lambda failure detected: LambdaAlarm"
        }

        formatted_message = format_message(self.sns_event)
        self.assertEqual(expected_message, formatted_message)

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch('main.urllib3.PoolManager', spec=True)
    def test_calls_poolmanager_on_urllib3_with_correct_params(self, mock_urllib_poolmanager):
        expected_headers = {'Content-Type': 'application/json; charset=UTF-8'}
        mock_pool_manager = mock_urllib_poolmanager.return_value

        self.secretsmanager_client_stubber.add_response('get_secret_value', self.response)
        self.secretsmanager_client_stubber.activate()

        lambda_handler(event=self.sns_event, secretsManagerClient=self.secretsmanager_client)

        mock_pool_manager.request.assert_called_once_with(
            'POST', 
            self.secret, 
            body=dumps(format_message(self.sns_event)), 
            headers=expected_headers
        )

