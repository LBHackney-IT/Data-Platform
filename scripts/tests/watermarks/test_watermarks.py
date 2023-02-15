import boto3
import botocore.session
from botocore.stub import Stubber

from scripts.helpers.watermarks import Watermarks

dynamodb = botocore.session.get_session
stubber.add_response(
    "query",
    {
        "Items": [
            {
                "jobName": {"S": "job-1"},
                "runId": {"S": "run-1"},
                "watermarks": {"M": {"watermark-1": {"S": "value-1"}}},
            },
            {
                "jobName": {"S": "job-1"},
                "runId": {"S": "run-2"},
                "watermarks": {"M": {"watermark-1": {"S": "value-2"}}},
            },
            {
                "jobName": {"S": "job-1"},
                "runId": {"S": "run-3"},
                "watermarks": {"M": {"watermark-1": {"S": "value-3"}}},
            },
        ],
        "Count": 3,
        "ScannedCount": 3,
    },
    expected_params={
        "TableName": "table-1",
        "KeyConditionExpression": "jobName = :jobName",
        "ExpressionAttributeValues": {":jobName": {"S": "job-1"}},
    },
)
stubber.activate()

watermarks = Watermarks("table-1", dynamodb_client=dynamodb)
run_id = watermarks.get_most_recent_run_id("job-1")
assert run_id == "run-3"

stubber.assert_no_pending_responses()().create_client("dynamodb", "eu-west-2")
stubber = Stubber(dynamodb)


class TestWatermarks:
    def test_get_most_recent_run_id(self):
        stubber.add_response(
            "query",
            {
                "Items": [
                    {
                        "jobName": {"S": "test_job"},
                        "runId": {"S": "test_run_id"},
                        "watermarks": {"M": {"key": {"S": "value"}}},
                    }
                ],
                "Count": 1,
                "ScannedCount": 1,
                "LastEvaluatedKey": {
                    "jobName": {"S": "test_job"},
                    "runId": {"S": "test_run_id"},
                },
            },
        )
        stubber.activate()
        watermarks = Watermarks("test_table", dynamodb_client=dynamodb)
        assert watermarks.get_most_recent_run_id("test_job") == "test_run_id"

    def test_exists(self):
        stubber.add_response(
            "describe_table",
            {
                "Table": {
                    "AttributeDefinitions": [
                        {"AttributeName": "jobName", "AttributeType": "S"},
                        {"AttributeName": "runId", "AttributeType": "S"},
                    ],
                    "TableName": "test_table",
                    "KeySchema": [
                        {"AttributeName": "jobName", "KeyType": "HASH"},
                        {"AttributeName": "runId", "KeyType": "RANGE"},
                    ],
                    "TableStatus": "ACTIVE",
                    "CreationDateTime": 1584421488.0,
                    "ProvisionedThroughput": {
                        "LastIncreaseDateTime": 0.0,
                        "LastDecreaseDateTime": 0.0,
                        "NumberOfDecreasesToday": 1,
                        "ReadCapacityUnits": 5,
                        "WriteCapacityUnits": 5,
                    },
                    "TableSizeBytes": 0,
                    "ItemCount": 0,
                    "TableArn": (
                        "arn:aws:dynamodb:eu-west-2:1234567890:table/test_table"
                    ),
                    "TableId": "1234567890",
                }
            },
        )
        stubber.activate()
        watermarks = Watermarks("test_table", dynamodb_client=dynamodb)
        assert watermarks.exists("test_table") is True

    def test_create_watermark_item(self):
        watermarks = Watermarks("test_table", dynamodb_client=dynamodb)

        assert watermarks.create_watermark_item(
            "test_job", "test_run_id", rows="500"
        ) == {
            "jobName": "test_job",
            "runId": "test_run_id",
            "watermarks": {"rows": "500"},
        }

    def test_get_watermark_value(self):
        stubber.add_response(
            "query",
            {
                "Items": [
                    {
                        "jobName": {"S": "test_job"},
                        "runId": {"S": "test_run_id"},
                        "watermarks": {"M": {"key": {"S": "value"}}},
                    }
                ],
                "Count": 1,
                "ScannedCount": 1,
                "LastEvaluatedKey": {
                    "jobName": {"S": "test_job"},
                    "runId": {"S": "test_run_id"},
                },
            },
        )
        stubber.activate()
        watermarks = Watermarks("test_table", dynamodb_client=dynamodb)
        assert (
            watermarks.get_watermark_value("test_job", "key", "test_run_id") == "value"
        )
