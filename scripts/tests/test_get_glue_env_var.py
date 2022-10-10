from scripts.helpers.helpers import get_glue_env_var, get_glue_env_vars
from unittest.mock import patch


class TestGetGlueEnvVar:
  def test_can_get_an_env_var(self):
    args = [
        '/tmp/LLPG raw to trusted.py',
        '--source_catalog_database', 'dataplatform-stg-raw-zone-unrestricted-address-api',
        '--JOB_ID', 'j_7e089a7aab766580dd648928aa0abe6978e074912309f37950c21d855e4c48d0',
        '--JOB_RUN_ID', 'jr_ff2410b9b96fa1e6342ea1774d6e8335092b1a97ac600703d3fb07d19136d3bf',
        '--source_catalog_table', 'unrestricted_address_api_dbo_hackney_address',
        '--s3_bucket_target', 's3://dataplatform-stg-trusted-zone/unrestricted/llpg/latest_llpg',
        '--JOB_NAME', 'LLPG raw to trusted',
        '--TempDir', 's3://dataplatform-stg-glue-temp-storage/sandbox/'
    ]
    with patch("sys.argv", args):
        assert get_glue_env_var("source_catalog_database") == "dataplatform-stg-raw-zone-unrestricted-address-api"

class TestGetGlueEnvVars:
  def test_can_get_one_variable(self):
    args = [
        '/tmp/LLPG raw to trusted.py',
        '--source_catalog_database', 'dataplatform-stg-raw-zone-unrestricted-address-api',
        '--JOB_ID', 'j_7e089a7aab766580dd648928aa0abe6978e074912309f37950c21d855e4c48d0',
        '--JOB_RUN_ID', 'jr_ff2410b9b96fa1e6342ea1774d6e8335092b1a97ac600703d3fb07d19136d3bf',
        '--source_catalog_table', 'unrestricted_address_api_dbo_hackney_address',
        '--s3_bucket_target', 's3://dataplatform-stg-trusted-zone/unrestricted/llpg/latest_llpg',
        '--JOB_NAME', 'LLPG raw to trusted',
        '--TempDir', 's3://dataplatform-stg-glue-temp-storage/sandbox/'
    ]
    with patch("sys.argv", args):
        source_catalog_database, = get_glue_env_vars("source_catalog_database")
        assert source_catalog_database == "dataplatform-stg-raw-zone-unrestricted-address-api"

  def test_can_get_multiple_variables(self):
    args = [
        '/tmp/LLPG raw to trusted.py',
        '--source_catalog_database', 'dataplatform-stg-raw-zone-unrestricted-address-api',
        '--JOB_ID', 'j_7e089a7aab766580dd648928aa0abe6978e074912309f37950c21d855e4c48d0',
        '--JOB_RUN_ID', 'jr_ff2410b9b96fa1e6342ea1774d6e8335092b1a97ac600703d3fb07d19136d3bf',
        '--source_catalog_table', 'unrestricted_address_api_dbo_hackney_address',
        '--s3_bucket_target', 's3://dataplatform-stg-trusted-zone/unrestricted/llpg/latest_llpg',
        '--JOB_NAME', 'LLPG raw to trusted',
        '--TempDir', 's3://dataplatform-stg-glue-temp-storage/sandbox/'
    ]
    with patch("sys.argv", args):
        source_catalog_database, source_catalog_table = get_glue_env_vars("source_catalog_database", "source_catalog_table")
        assert source_catalog_database == "dataplatform-stg-raw-zone-unrestricted-address-api"
        assert source_catalog_table == "unrestricted_address_api_dbo_hackney_address"

  def test_gets_correct_variables_when_one_is_a_substring_of_another(self):
    args = [
        '/tmp/LLPG raw to trusted.py',
        '--source_catalog_database2', 'unrestricted-refined-zone',
        '--source_catalog_database', 'dataplatform-stg-raw-zone-unrestricted-address-api',
        '--JOB_ID', 'j_7e089a7aab766580dd648928aa0abe6978e074912309f37950c21d855e4c48d0',
        '--JOB_RUN_ID', 'jr_ff2410b9b96fa1e6342ea1774d6e8335092b1a97ac600703d3fb07d19136d3bf',
        '--source_catalog_table', 'unrestricted_address_api_dbo_hackney_address',
        '--s3_bucket_target', 's3://dataplatform-stg-trusted-zone/unrestricted/llpg/latest_llpg',
        '--JOB_NAME', 'LLPG raw to trusted',
        '--TempDir', 's3://dataplatform-stg-glue-temp-storage/sandbox/'
    ]
    with patch("sys.argv", args):
        source_catalog_database2, source_catalog_database = get_glue_env_vars("source_catalog_database2", "source_catalog_database")
        assert source_catalog_database == "dataplatform-stg-raw-zone-unrestricted-address-api"
        assert source_catalog_database2 == "unrestricted-refined-zone"