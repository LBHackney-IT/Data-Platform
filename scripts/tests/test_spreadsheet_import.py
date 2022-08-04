from scripts.jobs.spreadsheet_import import infer_file_type, load_file
from pyspark.sql import SQLContext
import pytest
import os


class TestXlsxImport:
    test_file_paths = [
        ("s3://path/to/xlsx/file/file_name.xlsx", "xlsx"),
        ("s3://path/to/csv/file/file_name.csv", "csv")
    ]

    test_file_types = [
        "xlsx",
        "csv"
    ]

    expected_columns = [
        "header_one",
        "header_two",
        "import_datetime",
        "import_timestamp",
        "import_year",
        "import_month",
        "import_day",
        "import_date"
    ]

    @pytest.mark.parametrize("input_file_path,expected_file_type", test_file_paths)
    def test_should_return_correct_inferred_file_type(self, input_file_path, expected_file_type):
        response = infer_file_type(input_file_path)
        assert response == expected_file_type

    @pytest.mark.parametrize("test_file_type", test_file_types)
    def test_should_convert_file_to_data_frame(self, spark, mocker, test_file_type):
        import scripts.jobs.spreadsheet_import
        mocker.patch('scripts.jobs.spreadsheet_import.create_dataframe_from_' + test_file_type, return_value=True)
        spy = mocker.spy(scripts.jobs.spreadsheet_import, 'create_dataframe_from_' + test_file_type)
        load_file(test_file_type, SQLContext(spark.sparkContext), "", 2, "")
        assert spy.call_count == 1

    def test_should_load_csv(self, spark):
        dataframe = load_file("csv", SQLContext(spark.sparkContext), "test_spreadsheet_import", 2, os.path.dirname(__file__) + "/test_data/test_spreadsheet_import.csv")
        assert dataframe.columns == TestXlsxImport.expected_columns
        assert dataframe.rdd.count() == 2
