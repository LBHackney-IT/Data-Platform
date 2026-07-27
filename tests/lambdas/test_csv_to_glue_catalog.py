"""Tests for the user-uploaded CSV to Glue Catalog Lambda."""

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


def test_parse_s3_key_uses_table_subfolder() -> None:
    """Use the table folder for the recommended four-level key format."""
    result = main.parse_s3_key("parking/ringgo/permits/permits_march.csv")

    assert result == ("parking", "ringgo", "permits")


def test_parse_s3_key_keeps_legacy_format_compatible() -> None:
    """Use the file stem for a legacy three-level key."""
    result = main.parse_s3_key("parking/ringgo/permits_march.csv")

    assert result == ("parking", "ringgo", "permits_march")


def test_parse_s3_key_rejects_ambiguous_nested_paths() -> None:
    """Reject paths deeper than the documented table-folder layout."""
    with pytest.raises(ValueError, match="Invalid S3 key format"):
        main.parse_s3_key("parking/ringgo/permits/2026/permits_march.csv")


@patch.object(main, "extract_csv_column_definitions", return_value={"id": "string"})
@patch.object(main, "create_glue_table")
def test_process_record_creates_table_from_project_and_table_folders(
    create_glue_table: MagicMock,
    _extract_csv_column_definitions: MagicMock,
) -> None:
    """Create an independent table from the project and table folder names."""
    record = {
        "eventName": "ObjectCreated:Put",
        "s3": {
            "bucket": {"name": "dataplatform-prod-user-uploads"},
            "object": {
                "key": "parking/ringgo/permits/permits_march.csv",
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
        s3_key="parking/ringgo/permits/permits_march.csv",
        columns_types={"id": "string"},
    )


@patch.object(main.wr.catalog, "create_csv_table")
def test_create_glue_table_uses_table_subfolder_as_location(
    create_csv_table: MagicMock,
) -> None:
    """Point the Glue table at only its dedicated table subfolder."""
    main.create_glue_table(
        database_name="parking_user_uploads_db",
        table_name="ringgo_permits",
        bucket="dataplatform-prod-user-uploads",
        s3_key="parking/ringgo/permits/permits_march.csv",
        columns_types={"id": "string"},
    )

    create_csv_table.assert_called_once_with(
        database="parking_user_uploads_db",
        table="ringgo_permits",
        path=(
            "s3://dataplatform-prod-user-uploads/"
            "parking/ringgo/permits/"
        ),
        columns_types={"id": "string"},
        mode="overwrite",
        skip_header_line_count=1,
    )
