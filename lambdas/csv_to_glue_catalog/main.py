"""Synchronize user-uploaded CSV and TSV files with AWS Glue Catalog tables.

Inputs:
    Receives S3 object-created and object-removed events through SQS.

Outputs:
    Creates, updates, or deletes Glue Catalog tables for supported uploads.

Operational notes:
    All generated columns use the Glue ``string`` type. The recommended S3 key
    format is ``<department>/<target_table_name>/<file.csv|file.tsv>``. Every
    file in a target table folder contributes data to the same Glue table and
    must use the same extension and delimiter.
"""

import csv
import json
import logging
import os
import re
import unicodedata
from pathlib import PurePosixPath
from typing import Any
from urllib.parse import unquote_plus

import awswrangler as wr
import boto3
from botocore.config import Config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

OPEN_CSV_SERDE = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
QUOTE_CHARACTER = '"'
ESCAPE_CHARACTER = "\\"
CSV_SAMPLE_BYTE_COUNT = 65_536
DEFAULT_CSV_DELIMITER = ","
SUPPORTED_CSV_DELIMITERS = (",", "\t", "|")
SUPPORTED_FILE_EXTENSIONS = (".csv", ".tsv")
EXPECTED_BUCKET_OWNER = os.environ["EXPECTED_BUCKET_OWNER"]
DELIMITER_NAMES = {
    ",": "comma",
    "\t": "tab",
    "|": "pipe",
}
S3_CLIENT = boto3.client(
    "s3",
    config=Config(
        connect_timeout=3,
        read_timeout=10,
    ),
)


def read_csv_sample(bucket: str, key: str) -> str:
    """Read the beginning of a CSV object for delimiter detection.

    Args:
        bucket: S3 bucket name.
        key: S3 object key.

    Returns:
        UTF-8 decoded sample from the beginning of the object.

    Raises:
        ValueError: If the sample cannot be downloaded or decoded.
    """
    try:
        response = S3_CLIENT.get_object(
            Bucket=bucket,
            Key=key,
            Range=f"bytes=0-{CSV_SAMPLE_BYTE_COUNT - 1}",
            ExpectedBucketOwner=EXPECTED_BUCKET_OWNER,
        )
        sample_bytes = response["Body"].read()
        return sample_bytes.decode("utf-8-sig")
    except Exception as error:
        logger.exception("Failed to sample CSV from S3")
        raise ValueError(f"Unable to sample CSV file: {error}") from error


def detect_delimiter_from_sample(sample: str) -> str:
    """Detect a supported CSV delimiter from a text sample.

    Args:
        sample: Text sampled from the beginning of a CSV file.

    Returns:
        Detected comma, tab, or pipe delimiter.

    Raises:
        ValueError: If the sample is empty or its delimiter is unsupported or
            ambiguous.
    """
    if not sample.strip():
        raise ValueError("CSV file is empty")

    try:
        dialect = csv.Sniffer().sniff(
            sample,
            delimiters="".join(SUPPORTED_CSV_DELIMITERS),
        )
        return dialect.delimiter
    except csv.Error:
        header = next(
            (line for line in sample.splitlines() if line.strip()),
            "",
        )
        candidate_delimiters = [
            delimiter
            for delimiter in SUPPORTED_CSV_DELIMITERS
            if len(
                next(
                    csv.reader(
                        [header],
                        delimiter=delimiter,
                        quotechar=QUOTE_CHARACTER,
                        escapechar=ESCAPE_CHARACTER,
                    )
                )
            )
            > 1
        ]

        if len(candidate_delimiters) == 1:
            return candidate_delimiters[0]

        if not candidate_delimiters and ";" not in header:
            logger.warning(
                "No delimiter found in a single-column CSV header; "
                "defaulting to comma"
            )
            return DEFAULT_CSV_DELIMITER

        raise ValueError(
            "Unable to detect one supported CSV delimiter "
            "(comma, tab, or pipe)"
        )


def detect_csv_delimiter(bucket: str, key: str) -> str:
    """Detect the delimiter used by a CSV object in S3.

    Args:
        bucket: S3 bucket name.
        key: S3 object key.

    Returns:
        Detected comma, tab, or pipe delimiter.
    """
    return detect_delimiter_from_sample(read_csv_sample(bucket, key))


def get_supported_file_extension(file_path: str) -> str:
    """Return the supported lowercase extension from a file path.

    Args:
        file_path: S3 key or URI ending with a file name.

    Returns:
        The lowercase ``.csv`` or ``.tsv`` extension.

    Raises:
        ValueError: If the extension is not supported.
    """
    extension = PurePosixPath(file_path).suffix
    if extension not in SUPPORTED_FILE_EXTENSIONS:
        raise ValueError(
            "File must use a lowercase .csv or .tsv extension: "
            f"{PurePosixPath(file_path).name}"
        )

    return extension


def get_file_delimiter(bucket: str, key: str) -> str:
    """Return the delimiter declared or detected for a supported file.

    TSV files deterministically use Tab. CSV files retain content-based
    delimiter detection for comma, Tab, or pipe.

    Args:
        bucket: S3 bucket name.
        key: S3 object key.

    Returns:
        Delimiter used by the file.
    """
    if get_supported_file_extension(key) == ".tsv":
        return "\t"

    return detect_csv_delimiter(bucket, key)


def parse_s3_key(s3_key: str) -> tuple[str, str]:
    """Extract the department and target table name from an S3 key.

    The required format is
    ``<department>/<target_table_name>/<file.csv|file.tsv>``. The file name
    does not contribute to the Glue table name.

    Args:
        s3_key: URL-encoded S3 object key.

    Returns:
        Department and target table folder name.

    Raises:
        ValueError: If the key does not use a supported path or file format.
    """
    decoded_key = unquote_plus(s3_key)
    path = PurePosixPath(decoded_key)

    if len(path.parts) != 3:
        raise ValueError(
            f"Invalid S3 key format: {s3_key}. Expected "
            "<department>/<target_table_name>/<file.csv|file.tsv>"
        )

    get_supported_file_extension(decoded_key)

    department = path.parts[0]
    target_table_name = path.parts[1]

    return department, target_table_name


def normalize_name(name: str, lowercase: bool = True) -> str:
    """Replace all non-alphanumeric name characters with underscores.

    Strips accents, and converts to lowercase (optional). Consecutive
    non-alphanumeric characters are replaced with a single underscore.

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


def extract_csv_column_definitions(
    bucket: str,
    key: str,
    delimiter: str,
) -> dict[str, str]:
    """Extract, normalize, and deduplicate columns from a CSV or TSV file.

    Returns dictionary mapping column names to types (all string type).

    Args:
        bucket: S3 bucket name.
        key: S3 object key.
        delimiter: Character separating fields in the file.

    Returns:
        Dictionary mapping column names to the Glue ``string`` type.

    Raises:
        ValueError: If the file cannot be read or has an invalid header row.
    """
    s3_path = f"s3://{bucket}/{key}"

    try:
        df = wr.s3.read_csv(
            path=s3_path,
            sep=delimiter,
            quotechar=QUOTE_CHARACTER,
            escapechar=ESCAPE_CHARACTER,
            nrows=1,
            use_threads=False,
            encoding="utf-8-sig",
            on_bad_lines="skip",
        )
    except Exception as error:
        logger.error("Failed to read delimited file from S3: %s", error)
        raise ValueError(f"Unable to read delimited file: {error}") from error

    if len(df.columns) == 0:
        raise ValueError("File has no header row")

    column_names = list(df.columns)

    if not column_names or all(
        not col or col.strip() == ""
        for col in column_names
    ):
        raise ValueError("File has empty or invalid header row")

    normalized_headers = [normalize_name(col) for col in column_names]
    deduped_headers = deduplicate_column_names(normalized_headers)

    columns_types = {}
    for col_name in deduped_headers:
        if not col_name:
            col_name = f"column_{len(columns_types)}"
        columns_types[col_name] = "string"

    logger.info(
        f"A total of {len(columns_types)} column definitions were extracted "
        "from the file header"
    )
    return columns_types


def create_glue_table(
    database_name: str,
    table_name: str,
    bucket: str,
    s3_key: str,
    columns_types: dict[str, str],
    delimiter: str,
) -> None:
    """Create or recreate a Glue Catalog table for a CSV or TSV file.

    Args:
        database_name: Glue database name.
        table_name: Glue table name.
        bucket: S3 bucket name.
        s3_key: S3 object key.
        columns_types: Dictionary mapping column names to types.
        delimiter: Character separating fields in the file.
    """
    s3_location = build_s3_directory_location(bucket, s3_key)

    wr.catalog.create_csv_table(
        database=database_name,
        table=table_name,
        path=s3_location,
        columns_types=columns_types,
        mode="overwrite",
        sep=delimiter,
        skip_header_line_count=1,
        serde_library=OPEN_CSV_SERDE,
        serde_parameters={
            "separatorChar": delimiter,
            "quoteChar": QUOTE_CHARACTER,
            "escapeChar": ESCAPE_CHARACTER,
        },
    )
    logger.info("Successfully created table: %s in database: %s",
                table_name, database_name)


def build_s3_directory_location(bucket: str, s3_key: str) -> str:
    """Build the S3 URI for the directory containing an object.

    Args:
        bucket: S3 bucket name.
        s3_key: S3 object key.

    Returns:
        S3 directory URI with a trailing slash.
    """
    s3_directory = s3_key.rsplit("/", 1)[0]
    return f"s3://{bucket}/{s3_directory}/"


def list_table_files(bucket: str, s3_key: str) -> list[str]:
    """List supported lowercase files in the object's table folder.

    Args:
        bucket: S3 bucket name.
        s3_key: S3 object key.

    Returns:
        S3 URIs for lowercase CSV and TSV files in the table folder.
    """
    return wr.s3.list_objects(
        path=build_s3_directory_location(bucket, s3_key),
        suffix=list(SUPPORTED_FILE_EXTENSIONS),
    )


def detect_table_delimiter(bucket: str, file_paths: list[str]) -> str:
    """Require all files in a table folder to use one format and delimiter.

    Args:
        bucket: S3 bucket name.
        file_paths: S3 URIs for files in one table folder.

    Returns:
        The single delimiter detected across the table folder.

    Raises:
        ValueError: If no files remain or extensions or delimiters are mixed.
    """
    if not file_paths:
        raise ValueError(
            "No CSV or TSV files remain in the target table folder"
        )

    file_keys = [
        get_s3_key_from_uri(file_path, bucket)
        for file_path in file_paths
    ]
    extensions = {
        get_supported_file_extension(file_key)
        for file_key in file_keys
    }
    if len(extensions) != 1:
        raise ValueError(
            "All files in a target table folder must use the same extension; "
            f"detected: {', '.join(sorted(extensions))}"
        )

    delimiters = {
        get_file_delimiter(
            bucket,
            file_key,
        )
        for file_key in file_keys
    }
    if len(delimiters) != 1:
        delimiter_names = ", ".join(
            sorted(DELIMITER_NAMES[delimiter] for delimiter in delimiters)
        )
        raise ValueError(
            "All files in a target table folder must use the same "
            f"delimiter; detected: {delimiter_names}"
        )

    return next(iter(delimiters))


def get_s3_key_from_uri(s3_uri: str, bucket: str) -> str:
    """Extract an object key from an S3 URI in the expected bucket.

    Args:
        s3_uri: Fully qualified S3 object URI.
        bucket: Expected S3 bucket name.

    Returns:
        Object key without the bucket prefix.

    Raises:
        ValueError: If the URI is not in the expected bucket.
    """
    bucket_prefix = f"s3://{bucket}/"
    if not s3_uri.startswith(bucket_prefix):
        raise ValueError(
            f"Unexpected S3 URI returned while listing files: {s3_uri}"
        )

    return s3_uri.removeprefix(bucket_prefix)


def delete_glue_table(database_name: str, table_name: str) -> None:
    """Delete Glue Catalog table using AWS Data Wrangler.

    Args:
        database_name: Glue database name
        table_name: Glue table name
    """
    wr.catalog.delete_table_if_exists(database=database_name, table=table_name)
    logger.info("Successfully deleted table: %s from database: %s",
                table_name, database_name)


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
    logger.info(
        "Processing event: %s for s3://%s/%s",
        event_name,
        bucket,
        decoded_s3_key,
    )

    _, target_table_name = parse_s3_key(s3_key)
    table_name = normalize_name(target_table_name)

    if not table_name:
        raise ValueError(
            "Target table folder must contain alphanumeric characters: "
            f"{s3_key}"
        )

    if event_name.startswith("ObjectCreated"):
        logger.info(f"Creating/updating table: {table_name}")

        table_files = list_table_files(bucket, decoded_s3_key)
        delimiter = detect_table_delimiter(bucket, table_files)
        columns_types = extract_csv_column_definitions(
            bucket,
            decoded_s3_key,
            delimiter,
        )

        create_glue_table(
            database_name=database_name,
            table_name=table_name,
            bucket=bucket,
            s3_key=decoded_s3_key,
            columns_types=columns_types,
            delimiter=delimiter,
        )

        logger.info("Successfully processed upload: %s -> table: %s",
                    decoded_s3_key, table_name)
        return True, False

    if event_name.startswith("ObjectRemoved"):
        s3_location = build_s3_directory_location(bucket, decoded_s3_key)
        remaining_files = list_table_files(bucket, decoded_s3_key)

        if remaining_files:
            delimiter = detect_table_delimiter(bucket, remaining_files)
            remaining_s3_key = get_s3_key_from_uri(
                sorted(remaining_files)[0],
                bucket,
            )
            columns_types = extract_csv_column_definitions(
                bucket,
                remaining_s3_key,
                delimiter,
            )
            create_glue_table(
                database_name=database_name,
                table_name=table_name,
                bucket=bucket,
                s3_key=remaining_s3_key,
                columns_types=columns_types,
                delimiter=delimiter,
            )
            logger.info(
                f"Rebuilt table: {table_name}; {len(remaining_files)} "
                f"supported file(s) remain in {s3_location}"
            )
            return True, False

        logger.info(f"Deleting table: {table_name}")

        delete_glue_table(database_name=database_name, table_name=table_name)

        logger.info(
            f"Successfully processed deletion: {decoded_s3_key} "
            f"-> deleted table: {table_name}"
        )
        return True, False

    logger.warning(f"Unsupported event type: {event_name}")
    return False, True


def extract_s3_event_from_sqs_record(
    sqs_record: dict[str, Any],
) -> dict[str, Any]:
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

    Process each SQS message, extract S3 events, and handle partial batch
    failures.

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
                logger.warning(
                    "No S3 event found in SQS message %s",
                    message_id,
                )
                skipped_count += 1
                continue

            s3_key = (
                s3_event_record.get("s3", {})
                .get("object", {})
                .get("key", "unknown")
            )
            logger.info(f"Processing file from message {message_id}: {s3_key}")

            # Normalize the S3 department to construct the database name.
            department, _ = parse_s3_key(s3_key)
            normalized_dept = department.replace("-", "_")
            database_name = f"{normalized_dept}_user_uploads_db"
            logger.info(
                "Using database '%s' for department '%s'",
                database_name,
                department,
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
        f"{skipped_count} skipped, {len(failed_message_ids)} failed, "
        f"{total_records} total"
    )

    return {
        "batchItemFailures": [
            {"itemIdentifier": message_id} for message_id in failed_message_ids
        ]
    }


def lambda_handler(event: dict[str, Any], context: object) -> dict[str, Any]:
    """Lambda function handler for SQS events and batchItemFailures."""
    return handle_sqs_event(event)
