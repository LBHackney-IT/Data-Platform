from datetime import datetime
from unittest import TestCase

from mtfh_export_lambda.main import (
    add_date_partition_key_to_s3_prefix,
    create_table_arn,
    secret_string_to_dict,
)


class TestMtfhExportLambda(TestCase):
    def test_secret_string_to_dict(self):
        assert secret_string_to_dict(
            '{"kms_key": "test_kms_key", "role_arn": "test_role arn",'
            ' "dynamo_account_id": "test_dynamo_account_id", "s3_account_id":'
            ' "test_s3_account_id"}'
        ) == {
            "kms_key": "test_kms_key",
            "role_arn": "test_role arn",
            "dynamo_account_id": "test_dynamo_account_id",
            "s3_account_id": "test_s3_account_id",
        }

    def test_create_table_arn(self):
        assert (
            create_table_arn("my_table", "1234567890", "test-region-1")
            == "arn:aws:dynamodb:test-region-1:1234567890:table/my_table"
        )
        assert (
            create_table_arn("another_table", "0987654321", "test-region-2")
            == "arn:aws:dynamodb:test-region-2:0987654321:table/another_table"
        )

    def test_add_date_partition_key_to_s3_prefix(self):
        s3_prefix = "s3://my_bucket/data/"
        result = add_date_partition_key_to_s3_prefix(s3_prefix)
        t = datetime.today()
        expected = f"s3://my_bucket/data/import_year={t.strftime('%Y')}/import_month={t.strftime('%m')}/import_day={t.strftime('%d')}/import_date={t.strftime('%Y%m%d')}/"
        assert result == expected
