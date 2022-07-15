from pytest import MonkeyPatch
from zipfile import ZipFile

from alloy_api_ingestion import download_file_to_df
from scripts.jobs.env_services.alloy_api_ingestion import download_export


class alloy_api_ingestion_test():
    
    def test_download_export_invalid_key(monkeypatch: MonkeyPatch):
        with self.assertRaises(ValueError):
            export = download_export("123", "")

    @patch('awsglue.context.GlueContext')
    @patch('awsglue.utils.getResolvedOptions', side_effect=mock_get_resolved_options)
    def test_method(self, mock_resolve_options, mock_glue_context):
        <your code>

    def test_format_time()





