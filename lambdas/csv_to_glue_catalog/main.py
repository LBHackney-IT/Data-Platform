"""
Automatically creates/deletes Glue Catalog tables when CSV files are uploaded/deleted in S3.

Note: all column types of the created tables are defined as strings and please be aware when using them downstream.
"""

import json
import logging
import re
import unicodedata
from pathlib import PurePosixPath
from typing import Any
from urllib.parse import unquote_plus

import awswrangler as wr

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def parse_s3_key(s3_key: str) -> tuple[str, str, str]:
    """Parse S3 key to extract department, user_name, and file_name.

    Expected format: <department>/<user_name>/<file.csv>
    Example: parking/davina/test_1.csv

    Args:
        s3_key: URL-encoded S3 object key

    Returns:
        Tuple of (department, user_name, file_base_name)
    """
    decoded_key = unquote_plus(s3_key)
    path = PurePosixPath(decoded_key)

    if len(path.parts) < 3:
        raise ValueError(
            f"Invalid S3 key format: {s3_key}. Expected format: <department>/<user_name>/<file.csv>"
        )

    if path.suffix != ".csv":
        raise ValueError(f"File must be a CSV file: {path.name}")

    department = path.parts[0]
    user_name = path.parts[1]
    file_base_name = path.stem

    return department, user_name, file_base_name


def normalize_name(name: str, lowercase: bool = True) -> str:
    """Normalize name by replacing all non-alphanumeric characters with underscores.

    Strips accents, and converts to lowercase (optional). Consecutive non-alphanumeric
    characters are replaced with a single underscore.

    Args:
        name: Original name (column name, file name, user name, etc.)
        lowercase: Whether to convert to lowercase (default: True)

    Returns:
        Normalized name
    """
    formatted_name = name.lower() if lowercase else name
    formatted_name = unicodedata.normalize("NFKD", formatted_name)
    formatted_name = re.sub(r"[^a-zA-Z0-9]+", "_", formatted_name)
    formatted_name = formatted_name.strip("_")
    return formatted_name


def deduplicate_column_names(columns: list[str]) -> list[str]:
    """Deduplicate column names by appending a counter to duplicate names.

    Args:
        columns: List of column names (may contain duplicates)

    Returns:
        List of deduplicated column names
    """
    deduped_headers = []
    header_counts = {}

    for col in columns:
        if col in header_counts:
            header_counts[col] += 1
            deduped_headers.append(f"{col}_{header_counts[col]}")
        else:
            header_counts[col] = 0
            deduped_headers.append(col)

    return deduped_headers


def extract_csv_column_definitions(bucket: str, key: str) -> dict[str, str]:
    """Extract column names from CSV header, normalize and deduplicate them.

    Returns dictionary mapping column names to types (all string type).

    Args:
        bucket: S3 bucket name
        key: S3 object key (file path)

    Returns:
        Dictionary mapping column names to types (all 'string')

    Raises:
        ValueError: If CSV file has no header row or empty header row
    """
    s3_path = f"s3://{bucket}/{key}"

    try:
        df = wr.s3.read_csv(
            path=s3_path,
            nrows=1,
            use_threads=False,
            encoding="utf-8-sig",
            on_bad_lines="skip",
        )
    except Exception as e:
        logger.error(f"Failed to read CSV from S3: {e}")
        raise ValueError(f"Unable to read CSV file: {e}") from e

    if len(df.columns) == 0:
        raise ValueError("CSV file has no header row")

    column_names = list(df.columns)

    if not column_names or all(not col or col.strip() == "" for col in column_names):
        raise ValueError("CSV file has empty or invalid header row")

    normalized_headers = [normalize_name(col) for col in column_names]
    deduped_headers = deduplicate_column_names(normalized_headers)

    columns_types = {}
    for col_name in deduped_headers:
        if not col_name:
            col_name = f"column_{len(columns_types)}"
        columns_types[col_name] = "string"

    logger.info(
        f"A total of {len(columns_types)} column definitions were extracted from CSV header"
    )
    return columns_types


def create_glue_table(
    database_name: str,
    table_name: str,
    bucket: str,
    s3_key: str,
    columns_types: dict[str, str],
):
    """Create or recreate Glue Catalog table using AWS Data Wrangler.

    Args:
        database_name: Glue database name
        table_name: Glue table name
        bucket: S3 bucket name
        s3_key: S3 object key (file path)
        columns_types: Dictionary mapping column names to types
    """
    # Extract directory path: s3://bucket/parking/user/file.csv -> s3://bucket/parking/user/
    s3_path_parts = s3_key.rsplit("/", 1)
    s3_directory = f"{s3_path_parts[0]}/" if len(s3_path_parts) > 1 else ""
    s3_location = f"s3://{bucket}/{s3_directory}"

    wr.catalog.create_csv_table(
        database=database_name,
        table=table_name,
        path=s3_location,
        columns_types=columns_types,
        mode="overwrite",
        skip_header_line_count=1,
    )
    logger.info(
        f"Successfully created table: {table_name} in database: {database_name}"
    )


def delete_glue_table(database_name: str, table_name: str):
    """Delete Glue Catalog table using AWS Data Wrangler.

    Args:
        database_name: Glue database name
        table_name: Glue table name
    """
    wr.catalog.delete_table_if_exists(database=database_name, table=table_name)
    logger.info(
        f"Successfully deleted table: {table_name} from database: {database_name}"
    )


def process_single_event_record(
    record: dict[str, Any], database_name: str
) -> tuple[bool, bool]:
    """Process a single S3 event record.

    Args:
        record: S3 event record dictionary
        database_name: Glue database name

    Returns:
        Tuple of (was_processed, was_skipped)

    Raises:
        Exception: If processing fails
    """
    event_name = record.get("eventName", "")
    s3_info = record.get("s3", {})
    bucket = s3_info.get("bucket", {}).get("name", "")
    s3_key = s3_info.get("object", {}).get("key", "")

    if not s3_key:
        logger.warning("No S3 key found in event record")
        return False, True

    decoded_s3_key = unquote_plus(s3_key)
    logger.info(f"Processing event: {event_name} for s3://{bucket}/{decoded_s3_key}")

    _, user_name, file_base_name = parse_s3_key(s3_key)
    table_name = f"{normalize_name(user_name)}_{normalize_name(file_base_name)}"

    if event_name.startswith("ObjectCreated"):
        logger.info(f"Creating/updating table: {table_name}")

        columns_types = extract_csv_column_definitions(bucket, decoded_s3_key)

        create_glue_table(
            database_name=database_name,
            table_name=table_name,
            bucket=bucket,
            s3_key=decoded_s3_key,
            columns_types=columns_types,
        )

        logger.info(
            f"Successfully processed upload: {decoded_s3_key} -> table: {table_name}"
        )
        return True, False

    elif event_name.startswith("ObjectRemoved"):
        logger.info(f"Deleting table: {table_name}")

        delete_glue_table(database_name=database_name, table_name=table_name)

        logger.info(
            f"Successfully processed deletion: {decoded_s3_key} -> deleted table: {table_name}"
        )
        return True, False

    else:
        logger.warning(f"Unsupported event type: {event_name}")
        return False, True


def extract_s3_event_from_sqs_record(sqs_record: dict[str, Any]) -> dict[str, Any]:
    """Extract S3 event from SQS message body.

    Args:
        sqs_record: SQS record containing S3 event in body

    Returns:
        S3 event record dictionary
    """
    body = sqs_record.get("body", "{}")
    s3_event = json.loads(body)

    if "Records" in s3_event and len(s3_event["Records"]) > 0:
        return s3_event["Records"][0]

    return {}


def handle_sqs_event(event: dict[str, Any]) -> dict[str, Any]:
    """Handle SQS event containing S3 event notifications.

    Process each SQS message, extract S3 events, and handle partial batch failures.

    Args:
        event: SQS event dictionary containing Records array of SQS messages

    Returns:
        Dictionary with batchItemFailures for partial batch failure handling
    """
    sqs_records = event.get("Records", [])
    total_records = len(sqs_records)
    processed_count = 0
    skipped_count = 0
    failed_message_ids = []

    logger.info(f"Processing {total_records} SQS message(s)")

    for sqs_record in sqs_records:
        message_id = sqs_record.get("messageId", "unknown")
        logger.info(f"Processing SQS message {message_id}")

        try:
            s3_event_record = extract_s3_event_from_sqs_record(sqs_record)

            if not s3_event_record:
                logger.warning(f"No S3 event found in SQS message {message_id}")
                skipped_count += 1
                continue

            s3_key = (
                s3_event_record.get("s3", {}).get("object", {}).get("key", "unknown")
            )
            logger.info(f"Processing file from message {message_id}: {s3_key}")

            # Extract and normalize department from S3 path to construct database name
            department, _, _ = parse_s3_key(s3_key)
            normalized_dept = department.replace("-", "_")
            database_name = f"{normalized_dept}_user_uploads_db"
            logger.info(
                f"Using database '{database_name}' for department '{department}'"
            )

            was_processed, was_skipped = process_single_event_record(
                s3_event_record, database_name
            )

            if was_processed:
                processed_count += 1
                logger.info(f"Successfully processed message {message_id}")
            elif was_skipped:
                skipped_count += 1
                logger.info(f"Skipped message {message_id}")

        except Exception as e:
            error_msg = f"Error processing SQS message {message_id}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            failed_message_ids.append(message_id)

    logger.info(
        f"Processing summary: {processed_count} processed, "
        f"{skipped_count} skipped, {len(failed_message_ids)} failed, {total_records} total"
    )

    return {
        "batchItemFailures": [
            {"itemIdentifier": message_id} for message_id in failed_message_ids
        ]
    }


def lambda_handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    """Lambda function handler for SQS events and batchItemFailures."""
    return handle_sqs_event(event)
