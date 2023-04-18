import unittest
from datetime import datetime
from unittest import mock

import boto3
from export_dynamodb_table.main import (
    add_date_partition_key_to_s3_prefix,
    export_dynamo_db_table,
)


class TestExportDynamoTable(unittest.TestCase):
    def setUp(self):
        self.client = boto3.client("dynamodb")
        self.table_arn = "arn:aws:dynamodb:us-west-2:123456789012:table/test-table"
        self.s3_bucket = "test-bucket"
        self.s3_prefix = "test-prefix"
        self.export_format = "DYNAMODB_JSON"
        self.s3_bucket_owner_id = None
        self.s3_ss3_algorithm = "KMS"
        self.kms_key = "test-kms-key"
        self.export_time = datetime.now()

    def test_export_dynamo_db_table(self):
        mock_response = {
            "ExportArn": "arn:aws:dynamodb:us-west-2:123456789012:table/test-table/export/12345678901234567890123456789012"
        }
        with mock.patch.object(
            self.client, "export_table_to_point_in_time", return_value=mock_response
        ) as mock_method:
            response = export_dynamo_db_table(
                self.client,
                self.table_arn,
                self.s3_bucket,
                self.s3_prefix,
                self.export_format,
                self.s3_bucket_owner_id,
                self.s3_ss3_algorithm,
                self.kms_key,
            )
            mock_method.assert_called_once_with(
                ExportTime=self.export_time,
                TableArn=self.table_arn,
                S3Bucket=self.s3_bucket,
                S3Prefix=self.s3_prefix,
                ExportFormat=self.export_format,
                S3BucketOwner=self.s3_bucket_owner_id,
                S3SseAlgorithm=self.s3_ss3_algorithm,
                S3SseKmsKeyId=self.kms_key,
            )
        self.assertEqual(response, mock_response)

    def test_add_date_partition_key_to_s3_prefix(self):
        s3_prefix = "test-prefix/"
        expected_prefix = f'{s3_prefix}import_year={datetime.today().strftime("%Y")}/import_month={datetime.today().strftime("%m")}/import_day={datetime.today().strftime("%d")}/import_date={datetime.today().strftime("%Y%m%d")}/'
        self.assertEqual(
            add_date_partition_key_to_s3_prefix(s3_prefix), expected_prefix
        )


if __name__ == "__main__":
    unittest.main()
