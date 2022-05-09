from jobs.xlsx_import import infer_file_type, load_file
import pytest


class TestXlsxImport:

    test_file_paths = [
        ("s3://path/to/xlsx/file/file_name.xlsx", "xlsx"),
        ("s3://path/to/csv/file/file_name.csv", "csv")
    ]

    test_file_types = [
        "xlsx",
        "csv"
    ]

    @pytest.mark.parametrize("input_file_path,expected_file_type", test_file_paths)
    def test_should_return_correct_inferred_file_type(self, input_file_path, expected_file_type):
        response = infer_file_type(input_file_path)
        assert response == expected_file_type

    @pytest.mark.parametrize("test_file_type", test_file_types)
    def test_should_convert_file_to_data_frame(self, mocker, test_file_type):
        import jobs.xlsx_import
        mocker.patch('jobs.xlsx_import.create_dataframe_from_' + test_file_type, return_value=True)
        spy = mocker.spy(jobs.xlsx_import, 'create_dataframe_from_' + test_file_type)
        load_file(test_file_type)
        assert spy.call_count == 1
