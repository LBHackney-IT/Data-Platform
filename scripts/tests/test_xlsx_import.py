from jobs.xlsx_import import infer_file_type,read_file_to_dataframe
import pytest
from unittest import TestCase


class TestXlsxImport(TestCase):
    test_file_paths = [
        ["s3://path/to/xlsx/file/file_name.xlsx", "xlsx"],
        ["s3://path/to/csv/file/file_name.csv", "csv"]
    ]

    test_file_types = [
        "xlsx",
        "csv"
    ]

    @pytest.mark.parametrize("input_file_path, expected_file_type", test_file_paths)
    def test_should_return_correct_inferred_file_type(self, input_file_path, expected_file_type):
        response = infer_file_type(input_file_path)
        self.assertEqual(response, expected_file_type)

    @pytest.mark.parametrize("input_file_type", test_file_types)
    def test_should_convert_file_to_data_frame(self, test_file_type):
        response = read_file_to_dataframe(test_file_type)
        self.assertEqual(response, "")
