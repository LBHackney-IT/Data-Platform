import unittest
from unittest.mock import MagicMock, patch

from rds_snapshot_export_s3_to_s3_copier.main import get_date_time, s3_copy_folder


class TestS3CopyFolder(unittest.TestCase):
    def setUp(self):
        self.s3_client = MagicMock()
        self.source_bucket = "source-bucket"
        self.source_prefix = "source-prefix"
        self.target_bucket = "target-bucket"
        self.target_prefix = "target-prefix"
        self.source_identifier = "sql-to-parquet-21-09-01-123456"

    def test_s3_copy_folder(self):
        self.s3_client.get_paginator.return_value.paginate.return_value = {
            "Contents": [
                {"Key": "database1/table1/file1.parquet"},
                {"Key": "database1/table1/file2.parquet"},
                {"Key": "database1/table2/file1.parquet"},
                {"Key": "database2/table1/file1.parquet"},
            ]
        }

        s3_copy_folder(
            self.s3_client,
            self.source_bucket,
            self.source_prefix,
            self.target_bucket,
            self.target_prefix,
            self.source_identifier,
        )

        self.s3_client.copy_object.assert_any_call(
            Bucket=self.target_bucket,
            CopySource=f"{self.source_bucket}/database1/table1/file1.parquet",
            Key=f"{self.target_prefix}/database1/table1/import_year=21/import_month=09/import_day=01/import_date=2021/file1.parquet",
            ACL="bucket-owner-full-control",
        )
        self.s3_client.copy_object.assert_any_call(
            Bucket=self.target_bucket,
            CopySource=f"{self.source_bucket}/database1/table1/file2.parquet",
            Key=f"{self.target_prefix}/database1/table1/import_year=21/import_month=09/import_day=01/import_date=2021/file2.parquet",
            ACL="bucket-owner-full-control",
        )
        self.s3_client.copy_object.assert_any_call(
            Bucket=self.target_bucket,
            CopySource=f"{self.source_bucket}/database1/table2/file1.parquet",
            Key=f"{self.target_prefix}/database1/table2/import_year=21/import_month=09/import_day=01/import_date=2021/file1.parquet",
            ACL="bucket-owner-full-control",
        )
        self.s3_client.copy_object.assert_any_call(
            Bucket=self.target_bucket,
            CopySource=f"{self.source_bucket}/database2/table1/file1.parquet",
            Key=f"{self.target_prefix}/database2/table1/import_year=21/import_month=09/import_day=01/import_date=2021/file1.parquet",
            ACL="bucket-owner-full-control",
        )

    def test_get_date_time(self):
        year, month, day, date = get_date_time(self.source_identifier)
        self.assertEqual(year, "21")
        self.assertEqual(month, "09")
        self.assertEqual(day, "01")
        self.assertEqual(date, "210901")


if __name__ == "__main__":
    unittest.main()
