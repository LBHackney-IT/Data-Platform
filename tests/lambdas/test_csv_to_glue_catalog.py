"""Tests for the user-uploaded CSV to Glue Catalog Lambda."""

import json
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock, patch

import pytest

LAMBDA_PATH = (
    Path(__file__).parents[2] / "lambdas" / "csv_to_glue_catalog" / "main.py"
)


def load_lambda_module() -> ModuleType:
    """Load the Lambda module without relying on its directory being on sys.path."""
    spec = spec_from_file_location("csv_to_glue_catalog_main", LAMBDA_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load Lambda module from {LAMBDA_PATH}")

    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


main = load_lambda_module()


def test_parse_s3_key_uses_target_table_folder() -> None:
    """Use the table folder and ignore different CSV file names."""
    january_result = main.parse_s3_key(
        "parking/ringgo_permits/january.csv"
    )
    february_result = main.parse_s3_key(
        "parking/ringgo_permits/february.csv"
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


def test_parse_s3_key_rejects_non_csv_files() -> None:
    """Reject files that do not have the lowercase CSV extension."""
    with pytest.raises(ValueError, match="File must be a CSV"):
        main.parse_s3_key("parking/ringgo_permits/permits.xlsx")


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


@patch.object(main, "extract_csv_column_definitions", return_value={"id": "string"})
@patch.object(main, "create_glue_table")
def test_process_record_creates_table_from_target_table_folder(
    create_glue_table: MagicMock,
    _extract_csv_column_definitions: MagicMock,
) -> None:
    """Create a table named after the target table folder."""
    record = {
        "eventName": "ObjectCreated:Put",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/permits_march.csv",
            },
        },
    }

    assert main.process_single_event_record(
        record, "parking_user_uploads_db"
    ) == (True, False)
    create_glue_table.assert_called_once_with(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo_permits/permits_march.csv",
        columns_types={"id": "string"},
    )


@patch.object(main.wr.catalog, "create_csv_table")
def test_create_glue_table_uses_target_table_folder_as_location(
    create_csv_table: MagicMock,
) -> None:
    """Point the Glue table at its dedicated target table folder."""
    main.create_glue_table(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo_permits/permits_march.csv",
        columns_types={"id": "string"},
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
        skip_header_line_count=1,
    )


@patch.object(main, "delete_glue_table")
@patch.object(
    main.wr.s3,
    "list_objects",
    return_value=[
        "s3://dataplatform-prod-user-uploads/"
        "parking/ringgo_permits/february.csv"
    ],
)
def test_process_delete_keeps_table_when_csv_files_remain(
    list_objects: MagicMock,
    delete_glue_table: MagicMock,
) -> None:
    """Keep the table while another CSV remains in its table folder."""
    record = {
        "eventName": "ObjectRemoved:Delete",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/january.csv",
            },
        },
    }

    assert main.process_single_event_record(
        record, "parking_user_uploads_db"
    ) == (True, False)
    list_objects.assert_called_once_with(
        path=(
            "s3://dataplatform-prod-user-uploads/"
            "parking/ringgo_permits/"
        ),
        suffix=".csv",
    )
    delete_glue_table.assert_not_called()


@patch.object(main, "delete_glue_table")
@patch.object(main.wr.s3, "list_objects", return_value=[])
def test_process_delete_removes_table_after_last_csv(
    _list_objects: MagicMock,
    delete_glue_table: MagicMock,
) -> None:
    """Delete the table when no CSV files remain in its table folder."""
    record = {
        "eventName": "ObjectRemoved:Delete",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo_permits/january.csv",
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
