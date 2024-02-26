import os
from datetime import datetime
from json import dumps
from unittest import TestCase, mock
from urllib.parse import quote

import botocore.session
from botocore.stub import Stubber
from glue_failure_gchat_notifications.main import (
    format_message,
    get_max_retries,
    get_run_attempt,
    lambda_handler,
)


class TestGlueAlarmsHandler(TestCase):
    mock_env_vars = {"SECRET_NAME": "test_secret_name"}

    def setUp(self):
        self.boto_session = botocore.session.get_session()
        self.boto_session.set_credentials("", "")
        self.secretsmanager_client = self.boto_session.create_client(
            "secretsmanager", region_name="test-region-2"
        )
        self.secretsmanager_client_stubber = Stubber(self.secretsmanager_client)

        self.secret = "secret_string_abc"

        self.response = {
            "ARN": "arn:aws:secretsmanager:eu-west-2:111111111:secret:secret-key",
            "Name": "string",
            "VersionId": "version_one_secret_name_11111111:version_one",
            "SecretBinary": b"bytes",
            "SecretString": self.secret,
            "VersionStages": [
                "string",
            ],
            "CreatedDate": datetime(2022, 1, 1),
        }

        self.job_name = "test job name"
        self.event_time = "2024-01-11T13:51:06Z"
        self.job_created_on = "2023-01-11T13:51:06Z"
        self.job_last_modified_on = "2023-01-12T13:51:06Z"
        self.test_run_id = "test_run_id123"

        self.cloudwatch_event = {
            "version": "0",
            "id": "test_id",
            "detail-type": "Glue Job State Change",
            "source": "aws.glue",
            "account": "test_account",
            "time": self.event_time,
            "region": "test-region-2",
            "resources": [],
            "detail": {
                "jobName": self.job_name,
                "severity": "ERROR",
                "state": "FAILED",
                "jobRunId": self.test_run_id,
                "message": "An error occurred while running the job.",
            },
        }

        self.glue_client = self.boto_session.create_client(
            "glue",
            region_name="test-region-2",
        )
        self.glue_client_stubber = Stubber(self.glue_client)

        self.get_job_response = {
            "Job": {
                "Name": self.job_name,
                "Role": "test_role",
                "CreatedOn": self.job_created_on,
                "LastModifiedOn": self.job_last_modified_on,
                "MaxRetries": 0,
                "ExecutionProperty": {"MaxConcurrentRuns": 1},
                "Command": {
                    "Name": "test_name",
                    "ScriptLocation": "test_location",
                },
                "DefaultArguments": {
                    "test_argument": "test_value",
                },
                "Connections": {
                    "Connections": ["test_connection"],
                },
                "Timeout": 360,
                "SecurityConfiguration": "test_security_configuration",
                "WorkerType": "Standard",
                "NumberOfWorkers": 10,
                "GlueVersion": "test_glue_version",
            }
        }

        self.get_job_run_response = {
            "JobRun": {
                "Id": self.test_run_id,
                "Attempt": 0,
                "PreviousRunId": "test_previous_run_id",
                "TriggerName": "test_trigger_name",
                "JobName": self.job_name,
                "StartedOn": "2024-01-11T13:51:06Z",
                "LastModifiedOn": "2024-01-11T13:55:06Z",
                "CompletedOn": "2024-01-11T13:58:06Z",
                "JobRunState": "FAILED",
                "Arguments": {
                    "test_argument": "test_value",
                },
                "ErrorMessage": "An error occurred while running the job.",
                "PredecessorRuns": [
                    {
                        "JobName": self.job_name,
                        "RunId": "test_run_id",
                    }
                ],
                "AllocatedCapacity": 10,
                "ExecutionTime": 100,
                "Timeout": 360,
                "MaxCapacity": 10.0,
                "WorkerType": "Standard",
                "NumberOfWorkers": 10,
                "SecurityConfiguration": "test_security_configuration",
                "LogGroupName": "test_log_group_name",
                "NotificationProperty": {
                    "NotifyDelayAfter": 100,
                },
                "GlueVersion": "test_glue_version",
            }
        }

        self.secret_name = "test_secret_name"

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch("urllib3.PoolManager", spec=True)
    def test_calls_get_secret_value_on_secret_manager_client_with_correct_secret_name(
        self, mock_urllib_poolmanager
    ):
        expected_params = {"SecretId": self.secret_name}
        self.secretsmanager_client_stubber.add_response(
            "get_secret_value", self.response, expected_params
        )
        self.secretsmanager_client_stubber.activate()

        self.glue_client_stubber.add_response("get_job", self.get_job_response)
        self.glue_client_stubber.activate()

        lambda_handler(
            event=self.cloudwatch_event,
            secretsManagerClient=self.secretsmanager_client,
            glueClient=self.glue_client,
        )

        self.secretsmanager_client_stubber.assert_no_pending_responses()

    def test_format_message_returns_correct_message(self):
        job_name_html_encoded = quote(self.job_name)
        expected_message = {
            "text": (
                f"{self.event_time} \nGlue failure detected for job: *{self.job_name}*"
                " \nrun:"
                f" https://test-region-2.console.aws.amazon.com/gluestudio/home?region=test-region-2#/job/{job_name_html_encoded}/run/test_run_id123"
                " \nError message: An error occurred while running the job."
            )
        }
        actual_message = format_message(self.cloudwatch_event)

        self.assertEqual(expected_message, actual_message)

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch("lambda_alarms_handler.main.urllib3.PoolManager", spec=True)
    def test_calls_poolmanager_on_urllib3_with_correct_params(
        self, mock_urllib_poolmanager
    ):
        expected_headers = {"Content-Type": "application/json; charset=UTF-8"}
        mock_pool_manager = mock_urllib_poolmanager.return_value

        self.secretsmanager_client_stubber.add_response(
            "get_secret_value", self.response
        )
        self.secretsmanager_client_stubber.activate()

        self.glue_client_stubber.add_response("get_job", self.get_job_response)
        self.glue_client_stubber.activate()

        lambda_handler(
            event=self.cloudwatch_event,
            secretsManagerClient=self.secretsmanager_client,
            glueClient=self.glue_client,
        )

        mock_pool_manager.request.assert_called_once_with(
            "POST",
            self.secret,
            body=dumps(format_message(self.cloudwatch_event)),
            headers=expected_headers,
        )

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch("lambda_alarms_handler.main.urllib3.PoolManager", spec=True)
    def test_does_not_call_poolmanager_on_urllib3_if_attempt_is_less_than_max_retries(
        self, mock_urllib_poolmanager
    ):
        self.get_job_response["Job"]["MaxRetries"] = 3
        self.glue_client_stubber.add_response("get_job", self.get_job_response)
        self.glue_client_stubber.activate()

        lambda_handler(
            event=self.cloudwatch_event,
            secretsManagerClient=self.secretsmanager_client,
            glueClient=self.glue_client,
        )

        mock_urllib_poolmanager.assert_not_called()

    @mock.patch.dict(os.environ, mock_env_vars)
    @mock.patch("lambda_alarms_handler.main.urllib3.PoolManager", spec=True)
    def test_does_not_call_poolmanager_on_urllib3_if_attempt_is_equal_to_max_retries(
        self, mock_urllib_poolmanager
    ):
        self.get_job_response["Job"]["MaxRetries"] = 1
        self.get_job_run_response["JobRun"]["Attempt"] = 1
        self.glue_client_stubber.add_response("get_job", self.get_job_response)
        self.glue_client_stubber.add_response("get_job_run", self.get_job_run_response)
        self.glue_client_stubber.activate()

        lambda_handler(
            event=self.cloudwatch_event,
            secretsManagerClient=self.secretsmanager_client,
            glueClient=self.glue_client,
        )

        mock_urllib_poolmanager.assert_not_called()

    def test_get_max_retries_returns_correct_max_retries(self):
        expected_max_retries = 0

        self.glue_client_stubber.add_response("get_job", self.get_job_response)
        self.glue_client_stubber.activate()

        actual_max_retries = get_max_retries(self.job_name, self.glue_client)

        self.assertEqual(expected_max_retries, actual_max_retries)

    def test_get_run_attempt_returns_correct_run_attempt(self):
        expected_run_attempt = 0

        self.glue_client_stubber.add_response("get_job_run", self.get_job_run_response)
        self.glue_client_stubber.activate()

        actual_run_attempt = get_run_attempt(
            self.job_name, self.test_run_id, self.glue_client
        )

        self.assertEqual(expected_run_attempt, actual_run_attempt)
