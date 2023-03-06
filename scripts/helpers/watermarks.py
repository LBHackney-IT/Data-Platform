import logging
import typing as t

import boto3
from boto3.dynamodb.types import TypeDeserializer, TypeSerializer
from botocore.client import ClientError

logger = logging.getLogger(__name__)


class Watermarks:
    """
    Encapsulates an Amazon DynamoDB table that stores watermarks or state
    checkpoints for AWS Glue jobs.
    """

    def __init__(self, table_name: str, dynamodb_client=None) -> None:
        """Initializes the Watermarks object.

        :param table_name: The name of the DynamoDB table.
        :param dynamodb_client: The DynamoDB client to use. If not provided, a
        new client will be created.
        """
        self.table_name = table_name
        self.dynamodb_client = dynamodb_client or boto3.client("dynamodb")
        self.deserializer = TypeDeserializer()
        self.serializer = TypeSerializer()

    def exists(self, table_name) -> bool:
        """Checks if the DynamoDB table exists."""
        try:
            self.dynamodb_client.describe_table(TableName=table_name)
            return True
        except ClientError as e:
            if e.response["Error"]["Code"] == "ResourceNotFoundException":
                return False
            raise e

    def add_watermark(self, watermark_item: dict) -> None:
        """Adds a watermark item to the DynamoDB table."""
        try:
            watermark_item_serialized = self.serializer.serialize(watermark_item)
            self.dynamodb_client.put_item(
                TableName=self.table_name,
                Item=watermark_item_serialized,
            )
        except ClientError as e:
            logger.error(
                "Could not add watermark item to DynamoDB table %s. Error code: %s: %s",
                self.table_name,
                e.response["Error"]["Code"],
                e.response["Error"]["Message"],
            )
            raise e

    def get_most_recent_run_id(self, job_id: str) -> str:
        """Gets the most recent run id for the given job id."""
        try:
            response = self.dynamodb_client.query(
                TableName=self.table_name,
                KeyConditionExpression="jobName = :jobName",
                ExpressionAttributeValues={":jobName": {"S": job_id}},
                ScanIndexForward=False,
                Limit=1,
            )
        except ClientError as e:
            logger.error(
                "Could not get most recent run id from DynamoDB table %s. Error code:"
                " %s: %s",
                self.table_name,
                e.response["Error"]["Code"],
                e.response["Error"]["Message"],
            )
            raise e
        return response["Items"][0]["runId"]["S"]

    def get_watermark(self, job_id: str, run_id: t.Optional[str] = None) -> dict:
        """Gets the watermark item for the given job and run id."""
        if run_id is None:
            run_id = self.get_most_recent_run_id(job_id)
        try:
            response = self.dynamodb_client.get_item(
                TableName=self.table_name,
                Key={"jobName": {"S": job_id}, "runId": {"S": run_id}},
            )
            deserialized_response = {
                k: self.deserializer.deserialize(v) for k, v in response["Item"].items()
            }
        except ClientError as e:
            logger.error(
                "Could not get watermark item from DynamoDB table %s. Error code:"
                " %s: %s",
                self.table_name,
                e.response["Error"]["Code"],
                e.response["Error"]["Message"],
            )
            raise e
        return deserialized_response

    def get_watermark_values(
        self, job_id: str, run_id: t.Optional[str] = None, key: str = "watermarks"
    ) -> str:
        """Gets the value of a watermark for the given job and run id."""
        watermark = self.get_watermark(job_id, run_id)
        return watermark[key]

    @staticmethod
    def create_watermark_item(
        job_id: str, run_id: str, key: str = "watermarks", **kwargs
    ) -> dict:
        """Creates a watermark item for the given job and run id."""
        item = {"jobName": job_id, "runId": run_id, key: kwargs}
        return item
