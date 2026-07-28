"""Tests for the user-uploaded CSV and TSV to Glue Catalog Lambda."""

import json
import os
from importlib.util import module_from_spec, spec_from_file_location
from io import StringIO
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import MagicMock, patch

import pandas as pd
import pytest

LAMBDA_PATH = (
    Path(__file__).parents[2] / "lambdas" / "csv_to_glue_catalog" / "main.py"
)


def load_lambda_module() -> tuple[ModuleType, MagicMock]:
    """Load the Lambda module without relying on its directory in sys.path."""
    spec = spec_from_file_location("csv_to_glue_catalog_main", LAMBDA_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load Lambda module from {LAMBDA_PATH}")

    module = module_from_spec(spec)
    with (
        patch.dict(
            os.environ,
            {"EXPECTED_BUCKET_OWNER": "123456789012"},
        ),
        patch("boto3.client") as boto3_client,
    ):
        spec.loader.exec_module(module)
    return module, boto3_client


main, boto3_client = load_lambda_module()


def test_s3_client_is_initialized_once_with_explicit_timeouts() -> None:
    """Configure the reusable S3 client with bounded network timeouts."""
    boto3_client.assert_called_once()
    assert boto3_client.call_args.args == ("s3",)
    config = boto3_client.call_args.kwargs["config"]
    assert config.connect_timeout == 3
    assert config.read_timeout == 10


def test_parse_s3_key_uses_target_table_folder() -> None:
    """Use the table folder and ignore different supported file names."""
    january_result = main.parse_s3_key(
        "parking/ringgo_permits/january.csv"
    )
    february_result = main.parse_s3_key(
        "parking/ringgo_permits/february.tsv"
    )

    assert january_result == ("parking", "ringgo_permits")
    assert february_result == ("parking", "ringgo_permits")


def test_parse_s3_key_rejects_missing_table_folder() -> None:
    """Reject a CSV uploaded directly beneath the department folder."""
    with pytest.raises(ValueError, match="Invalid S3 key format"):
        main.parse_s3_key("parking/permits_march.csv")


def test_parse_s3_key_rejects_nested_paths() -> None:
    """Reject paths deeper than the required table-folder layout."""
    with pytest.raises(ValueError, match="Invalid S3 key format"):
        main.parse_s3_key("parking/ringgo/permits/permits_march.csv")


@pytest.mark.parametrize("extension", [".xlsx", ".CSV", ".TSV", ".psv"])
def test_parse_s3_key_rejects_unsupported_or_uppercase_extensions(
    extension: str,
) -> None:
    """Accept only lowercase CSV and TSV extensions."""
    with pytest.raises(
        ValueError,
        match=r"lowercase \.csv or \.tsv extension",
    ):
        main.parse_s3_key(f"parking/ringgo_permits/permits{extension}")


@pytest.mark.parametrize(
    ("sample", "expected_delimiter"),
    [
        (
            "id,description\n"
            '1,"Secondary carer, residential care, or another caring role"\n',
            ",",
        ),
        (
            "id\tdescription\n"
            '1\t"Secondary carer, residential care, or another caring role"\n',
            "\t",
        ),
        (
            "id|description\n"
            '1|"Secondary carer, residential care, or another caring role"\n',
            "|",
        ),
    ],
)
def test_detect_delimiter_from_csv_content(
    sample: str,
    expected_delimiter: str,
) -> None:
    """Detect comma, tab, or pipe while respecting quoted commas."""
    assert main.detect_delimiter_from_sample(sample) == expected_delimiter


def test_detect_delimiter_defaults_single_column_csv_to_comma() -> None:
    """Use comma metadata when a one-column CSV has no separator to detect."""
    sample = 'description\n"One value"\n"Another value"\n'

    assert main.detect_delimiter_from_sample(sample) == ","


def test_detect_delimiter_rejects_semicolon_delimited_content() -> None:
    """Reject a delimiter outside the supported comma, tab, and pipe set."""
    sample = "id;description\n1;Unsupported delimiter\n"

    with pytest.raises(ValueError, match="comma, tab, or pipe"):
        main.detect_delimiter_from_sample(sample)


@patch.object(main, "S3_CLIENT")
def test_read_csv_sample_uses_bounded_s3_range(
    s3_client: MagicMock,
) -> None:
    """Read a bounded sample from the expected bucket owner."""
    body = MagicMock()
    body.read.return_value = b"\xef\xbb\xbfid|description\n"
    s3_client.get_object.return_value = {"Body": body}

    sample = main.read_csv_sample(
        "dataplatform-prod-user-uploads",
        "parking/notes/notes.csv",
    )

    assert sample == "id|description\n"
    s3_client.get_object.assert_called_once_with(
        Bucket="dataplatform-prod-user-uploads",
        Key="parking/notes/notes.csv",
        Range="bytes=0-65535",
        ExpectedBucketOwner="123456789012",
    )


@patch.object(main, "read_csv_sample")
def test_get_file_delimiter_uses_tab_for_tsv_without_sampling(
    read_csv_sample: MagicMock,
) -> None:
    """Treat the TSV extension as an explicit Tab delimiter declaration."""
    assert main.get_file_delimiter(
        "dataplatform-prod-user-uploads",
        "parking/notes/notes.tsv",
    ) == "\t"
    read_csv_sample.assert_not_called()


@patch.object(main, "detect_csv_delimiter", return_value="|")
def test_get_file_delimiter_detects_csv_content(
    detect_csv_delimiter: MagicMock,
) -> None:
    """Retain content-based delimiter detection for CSV files."""
    assert main.get_file_delimiter(
        "dataplatform-prod-user-uploads",
        "parking/notes/notes.csv",
    ) == "|"
    detect_csv_delimiter.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        "parking/notes/notes.csv",
    )


def test_extract_csv_columns_preserves_quoted_commas() -> None:
    """Treat a comma inside a double-quoted value as field content."""
    csv_text = (
        "id,description\n"
        '1,"Secondary carer, residential care, or another caring role"\n'
    )

    def read_csv_with_lambda_dialect(**kwargs: object) -> pd.DataFrame:
        """Read the fixture using the dialect passed to AWS Wrangler."""
        pandas_kwargs = {
            key: value
            for key, value in kwargs.items()
            if key not in {"path", "use_threads"}
        }
        data_frame = pd.read_csv(StringIO(csv_text), **pandas_kwargs)
        assert data_frame.loc[0, "description"] == (
            "Secondary carer, residential care, or another caring role"
        )
        return data_frame

    with patch.object(
        main.wr.s3,
        "read_csv",
        side_effect=read_csv_with_lambda_dialect,
    ):
        columns = main.extract_csv_column_definitions(
            "dataplatform-prod-user-uploads",
            "parking/caring/caring.csv",
            ",",
        )

    assert columns == {"id": "string", "description": "string"}


def test_extract_tsv_columns_preserves_unquoted_commas() -> None:
    """Treat commas in a Google Sheets TSV value as normal field content."""
    tsv_text = (
        "id\tdescription\n"
        "1\tSecondary carer, residential care, or another caring role\n"
    )

    def read_tsv_with_lambda_dialect(**kwargs: object) -> pd.DataFrame:
        """Read the fixture using the dialect passed to AWS Wrangler."""
        pandas_kwargs = {
            key: value
            for key, value in kwargs.items()
            if key not in {"path", "use_threads"}
        }
        data_frame = pd.read_csv(StringIO(tsv_text), **pandas_kwargs)
        assert data_frame.loc[0, "description"] == (
            "Secondary carer, residential care, or another caring role"
        )
        return data_frame

    with patch.object(
        main.wr.s3,
        "read_csv",
        side_effect=read_tsv_with_lambda_dialect,
    ):
        columns = main.extract_csv_column_definitions(
            "dataplatform-prod-user-uploads",
            "parking/caring/caring.tsv",
            "\t",
        )

    assert columns == {"id": "string", "description": "string"}


@pytest.mark.parametrize("delimiter", ["\t", "|"])
@patch.object(main.wr.s3, "read_csv")
def test_extract_columns_uses_detected_delimiter(
    read_csv: MagicMock,
    delimiter: str,
) -> None:
    """Use the detected delimiter with the shared quote and escape rules."""
    read_csv.return_value = SimpleNamespace(columns=["id", "description"])

    columns = main.extract_csv_column_definitions(
        "dataplatform-prod-user-uploads",
        "parking/notes/notes.csv",
        delimiter,
    )

    assert columns == {"id": "string", "description": "string"}
    read_csv.assert_called_once_with(
        path=(
            "s3://dataplatform-prod-user-uploads/"
            "parking/notes/notes.csv"
        ),
        sep=delimiter,
        quotechar='"',
        escapechar="\\",
        nrows=1,
        use_threads=False,
        encoding="utf-8-sig",
        on_bad_lines="skip",
    )


@patch.object(main, "get_file_delimiter", side_effect=[",", ","])
def test_detect_table_delimiter_accepts_matching_csv_files(
    get_file_delimiter: MagicMock,
) -> None:
    """Return the common delimiter used by all CSV files in a table folder."""
    file_paths = [
        "s3://dataplatform-prod-user-uploads/parking/permits/january.csv",
        "s3://dataplatform-prod-user-uploads/parking/permits/february.csv",
    ]

    assert main.detect_table_delimiter(
        "dataplatform-prod-user-uploads",
        file_paths,
    ) == ","
    assert get_file_delimiter.call_count == 2


@patch.object(main, "get_file_delimiter", side_effect=[",", "|"])
def test_detect_table_delimiter_rejects_mixed_delimiters(
    _get_file_delimiter: MagicMock,
) -> None:
    """Reject a table folder containing CSV files with different delimiters."""
    file_paths = [
        "s3://dataplatform-prod-user-uploads/parking/permits/january.csv",
        "s3://dataplatform-prod-user-uploads/parking/permits/february.csv",
    ]

    with pytest.raises(ValueError, match="same delimiter"):
        main.detect_table_delimiter(
            "dataplatform-prod-user-uploads",
            file_paths,
        )


@patch.object(main, "get_file_delimiter")
def test_detect_table_delimiter_rejects_mixed_extensions(
    get_file_delimiter: MagicMock,
) -> None:
    """Reject mixed CSV and TSV files before inspecting their delimiters."""
    file_paths = [
        "s3://dataplatform-prod-user-uploads/parking/permits/january.csv",
        "s3://dataplatform-prod-user-uploads/parking/permits/february.tsv",
    ]

    with pytest.raises(ValueError, match="same extension"):
        main.detect_table_delimiter(
            "dataplatform-prod-user-uploads",
            file_paths,
        )

    get_file_delimiter.assert_not_called()


def test_handle_sqs_event_reports_invalid_path_as_batch_failure() -> None:
    """Report an invalid CSV path so SQS can retry and route it to the DLQ."""
    s3_event = {
        "Records": [
            {
                "eventName": "ObjectCreated:Put",
                "s3": {
                    "bucket": {"name": "dataplatform-prod-user-uploads"},
                    "object": {
                        "key": "parking/ringgo/permits/permits.csv",
                    },
                },
            }
        ]
    }
    sqs_event = {
        "Records": [
            {
                "messageId": "invalid-path",
                "body": json.dumps(s3_event),
            }
        ]
    }

    assert main.handle_sqs_event(sqs_event) == {
        "batchItemFailures": [{"itemIdentifier": "invalid-path"}]
    }


@patch.object(main, "detect_table_delimiter", return_value="\t")
@patch.object(
    main,
    "list_table_files",
    return_value=[
        "s3://dataplatform-prod-user-uploads/"
        "parking/ringgo_permits/permits_march.tsv"
    ],
)
@patch.object(
    main,
    "extract_csv_column_definitions",
    return_value={"id": "string"},
)
@patch.object(main, "create_glue_table")
def test_process_upload_uses_detected_delimiter(
    create_glue_table: MagicMock,
    extract_csv_column_definitions: MagicMock,
    list_table_files: MagicMock,
    detect_table_delimiter: MagicMock,
) -> None:
    """Use one detected delimiter for header parsing and Glue metadata."""
    record = {
        "eventName": "ObjectCreated:Put",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/permits_march.tsv",
            },
        },
    }

    assert main.process_single_event_record(
        record, "parking_user_uploads_db"
    ) == (True, False)
    list_table_files.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        "parking/ringgo_permits/permits_march.tsv",
    )
    detect_table_delimiter.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        [
            "s3://dataplatform-prod-user-uploads/"
            "parking/ringgo_permits/permits_march.tsv"
        ],
    )
    extract_csv_column_definitions.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        "parking/ringgo_permits/permits_march.tsv",
        "\t",
    )
    create_glue_table.assert_called_once_with(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo_permits/permits_march.tsv",
        columns_types={"id": "string"},
        delimiter="\t",
    )


@patch.object(main, "create_glue_table")
@patch.object(main, "extract_csv_column_definitions")
@patch.object(
    main,
    "detect_table_delimiter",
    side_effect=ValueError("All files must use the same delimiter"),
)
@patch.object(
    main,
    "list_table_files",
    return_value=[
        "s3://dataplatform-prod-user-uploads/parking/notes/january.csv",
        "s3://dataplatform-prod-user-uploads/parking/notes/february.csv",
    ],
)
def test_process_upload_rejects_mixed_delimiters_without_overwriting_table(
    _list_table_files: MagicMock,
    _detect_table_delimiter: MagicMock,
    extract_csv_column_definitions: MagicMock,
    create_glue_table: MagicMock,
) -> None:
    """Reject mixed delimiters before reading or replacing Glue metadata."""
    record = {
        "eventName": "ObjectCreated:Put",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {"key": "parking/notes/february.csv"},
        },
    }

    with pytest.raises(ValueError, match="same delimiter"):
        main.process_single_event_record(record, "parking_user_uploads_db")

    extract_csv_column_definitions.assert_not_called()
    create_glue_table.assert_not_called()


@pytest.mark.parametrize("delimiter", [",", "\t", "|"])
@patch.object(main.wr.catalog, "create_csv_table")
def test_create_glue_table_uses_detected_csv_dialect(
    create_csv_table: MagicMock,
    delimiter: str,
) -> None:
    """Configure OpenCSVSerde with the detected CSV delimiter."""
    main.create_glue_table(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo_permits/permits_march.csv",
        columns_types={"id": "string"},
        delimiter=delimiter,
    )

    create_csv_table.assert_called_once_with(
        database="parking_user_uploads_db",
        table="ringgo_permits",
        path=(
            "s3://dataplatform-prod-user-uploads/"
            "parking/ringgo_permits/"
        ),
        columns_types={"id": "string"},
        mode="overwrite",
        sep=delimiter,
        skip_header_line_count=1,
        serde_library="org.apache.hadoop.hive.serde2.OpenCSVSerde",
        serde_parameters={
            "separatorChar": delimiter,
            "quoteChar": '"',
            "escapeChar": "\\",
        },
    )


@patch.object(main.wr.s3, "list_objects")
def test_list_table_files_uses_lowercase_csv_and_tsv_suffixes(
    list_objects: MagicMock,
) -> None:
    """List only lowercase CSV and TSV files that can contribute to a table."""
    list_objects.return_value = []

    assert main.list_table_files(
        "dataplatform-prod-user-uploads",
        "parking/ringgo_permits/january.csv",
    ) == []
    list_objects.assert_called_once_with(
        path=(
            "s3://dataplatform-prod-user-uploads/"
            "parking/ringgo_permits/"
        ),
        suffix=[".csv", ".tsv"],
    )


@patch.object(main, "delete_glue_table")
@patch.object(main, "create_glue_table")
@patch.object(
    main,
    "extract_csv_column_definitions",
    return_value={"id": "string"},
)
@patch.object(main, "detect_table_delimiter", return_value="\t")
@patch.object(
    main,
    "list_table_files",
    return_value=[
        "s3://dataplatform-prod-user-uploads/"
        "parking/ringgo_permits/february.tsv",
    ],
)
def test_process_delete_rebuilds_table_with_remaining_file_dialect(
    list_table_files: MagicMock,
    detect_table_delimiter: MagicMock,
    extract_csv_column_definitions: MagicMock,
    create_glue_table: MagicMock,
    delete_glue_table: MagicMock,
) -> None:
    """Rebuild the table using a remaining supported file's delimiter."""
    record = {
        "eventName": "ObjectRemoved:Delete",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/january.tsv",
            },
        },
    }

    assert main.process_single_event_record(
        record, "parking_user_uploads_db"
    ) == (True, False)
    list_table_files.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        "parking/ringgo_permits/january.tsv",
    )
    detect_table_delimiter.assert_called_once()
    extract_csv_column_definitions.assert_called_once_with(
        "dataplatform-prod-user-uploads",
        "parking/ringgo_permits/february.tsv",
        "\t",
    )
    create_glue_table.assert_called_once_with(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo_permits/february.tsv",
        columns_types={"id": "string"},
        delimiter="\t",
    )
    delete_glue_table.assert_not_called()


@patch.object(main, "delete_glue_table")
@patch.object(main, "list_table_files", return_value=[])
def test_process_delete_removes_table_after_last_supported_file(
    _list_table_files: MagicMock,
    delete_glue_table: MagicMock,
) -> None:
    """Delete the table when no CSV or TSV files remain in its table folder."""
    record = {
        "eventName": "ObjectRemoved:Delete",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/january.tsv",
            },
        },
    }

    assert main.process_single_event_record(
        record, "parking_user_uploads_db"
    ) == (True, False)
    delete_glue_table.assert_called_once_with(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
    )
