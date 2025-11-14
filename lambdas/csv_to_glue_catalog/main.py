import csv
import json
import logging
import re
import unicodedata
from os import getenv
from urllib.parse import unquote

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

glue_client = boto3.client("glue")
s3_client = boto3.client("s3")


def parse_s3_key(s3_key: str):
    """
    Parse S3 key to extract department, user_name, and file_name.
    Expected format: <department>/<user_name>/<file.csv>
    Example: parking/davina/test_1.csv
    Returns: (department, user_name, file_base_name)
    """
    decoded_key = unquote(s3_key)
    parts = decoded_key.split("/")

    if len(parts) < 3:
        raise ValueError(
            f"Invalid S3 key format: {s3_key}. Expected format: <department>/<user_name>/<file.csv>"
        )

    department = parts[0]
    user_name = parts[1]
    file_name = parts[-1]

    if not file_name.endswith(".csv"):
        raise ValueError(f"File must be a CSV file: {file_name}")

    file_base_name = file_name[:-4]  # Remove .csv extension

    return department, user_name, file_base_name


def get_table_name(user_name: str, file_base_name: str) -> str:
    """
    Generate Glue table name from user_name and file_base_name.
    Format: <user_name>_<file_base_name>
    Example: davina_test_1
    """
    # Replace any non-alphanumeric characters with underscore
    safe_user = re.sub(r"[^a-zA-Z0-9]", "_", user_name)
    safe_file = re.sub(r"[^a-zA-Z0-9]", "_", file_base_name)
    return f"{safe_user}_{safe_file}"


def normalize_column_name(column: str) -> str:
    """Normalize column name by replacing all non-alphanumeric characters with underscores.

    Strips accents, and converts to lowercase. Consecutive non-alphanumeric characters
    are replaced with a single underscore.

    Args:
        column: Original column name

    Returns:
        Normalized column name
    """
    formatted_name = column.lower()
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


def infer_csv_schema(bucket: str, key: str) -> list:
    """
    Read CSV file header and infer schema (all columns as string type).
    Returns list of column definitions for Glue table.
    """
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response["Body"].read().decode("utf-8")

        # Read first line as header
        reader = csv.reader(content.splitlines())
        header = next(reader)

        if not header:
            raise ValueError("CSV file has no header row")

        normalized_headers = [normalize_column_name(col.strip()) for col in header]
        deduped_headers = deduplicate_column_names(normalized_headers)

        columns = []
        for col_name in deduped_headers:
            if not col_name:
                col_name = f"column_{len(columns)}"

            columns.append({"Name": col_name, "Type": "string"})

        logger.info(f"Inferred schema with {len(columns)} columns from CSV header")
        return columns

    except Exception as e:
        logger.error(f"Failed to infer CSV schema: {e}")
        raise


def create_glue_table(
    database_name: str,
    table_name: str,
    bucket: str,
    s3_key: str,
    columns: list,
    glue_client=None,
):
    """
    Create or recreate Glue Catalog table.
    If table exists, it will be deleted and recreated.
    """
    glue_client = glue_client or boto3.client("glue")

    # Check if table exists and delete it
    try:
        glue_client.delete_table(DatabaseName=database_name, Name=table_name)
        logger.info(f"Deleted existing table: {table_name}")
    except glue_client.exceptions.EntityNotFoundException:
        logger.info(f"Table {table_name} does not exist, creating new one")
    except Exception as e:
        logger.warning(f"Error checking/deleting table {table_name}: {e}")

    # Extract directory path from S3 key
    # For s3://bucket/parking/user/file.csv, we want s3://bucket/parking/user/
    s3_path_parts = s3_key.rsplit("/", 1)
    s3_directory = f"{s3_path_parts[0]}/" if len(s3_path_parts) > 1 else ""

    # Create new table pointing to the user's directory
    table_input = {
        "Name": table_name,
        "StorageDescriptor": {
            "Columns": columns,
            "Location": f"s3://{bucket}/{s3_directory}",
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                "Parameters": {
                    "field.delim": ",",
                    "skip.header.line.count": "1",
                },
            },
        },
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {
            "classification": "csv",
            "skip.header.line.count": "1",
            "EXTERNAL": "TRUE",
        },
    }

    try:
        glue_client.create_table(DatabaseName=database_name, TableInput=table_input)
        logger.info(
            f"Successfully created table: {table_name} in database: {database_name}"
        )
    except Exception as e:
        error_msg = f"Failed to create Glue table {table_name}: {str(e)}"
        logger.error(error_msg)
        raise


def delete_glue_table(database_name: str, table_name: str, glue_client=None):
    """Delete Glue Catalog table."""
    glue_client = glue_client or boto3.client("glue")

    try:
        glue_client.delete_table(DatabaseName=database_name, Name=table_name)
        logger.info(
            f"Successfully deleted table: {table_name} from database: {database_name}"
        )
    except glue_client.exceptions.EntityNotFoundException:
        logger.info(f"Table {table_name} does not exist, nothing to delete")
    except Exception as e:
        error_msg = f"Failed to delete Glue table {table_name}: {str(e)}"
        logger.error(error_msg)
        raise


def handle_s3_event(event, context):
    """
    Handle S3 event (ObjectCreated or ObjectRemoved).
    Process each record in the event.
    """
    database_name = getenv("GLUE_DATABASE_NAME", "parking_user_uploads_db")

    for record in event.get("Records", []):
        event_name = record.get("eventName", "")
        s3_info = record.get("s3", {})
        bucket = s3_info.get("bucket", {}).get("name", "")
        s3_key = s3_info.get("object", {}).get("key", "")

        if not s3_key:
            logger.warning("No S3 key found in event record")
            continue

        logger.info(f"Processing event: {event_name} for s3://{bucket}/{s3_key}")

        try:
            department, user_name, file_base_name = parse_s3_key(s3_key)
            table_name = get_table_name(user_name, file_base_name)

            if event_name.startswith("ObjectCreated"):
                logger.info(f"Creating/updating table: {table_name}")

                columns = infer_csv_schema(bucket, s3_key)

                create_glue_table(
                    database_name=database_name,
                    table_name=table_name,
                    bucket=bucket,
                    s3_key=s3_key,
                    columns=columns,
                )

                logger.info(
                    f"Successfully processed upload: {s3_key} -> table: {table_name}"
                )

            elif event_name.startswith("ObjectRemoved"):
                logger.info(f"Deleting table: {table_name}")

                delete_glue_table(database_name=database_name, table_name=table_name)

                logger.info(
                    f"Successfully processed deletion: {s3_key} -> deleted table: {table_name}"
                )

            else:
                logger.warning(f"Unsupported event type: {event_name}")

        except Exception as e:
            error_msg = f"Error processing S3 event {event_name} for {s3_key}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            raise


def lambda_handler(event, context):
    try:
        handle_s3_event(event, context)
        return {
            "statusCode": 200,
            "body": json.dumps("Successfully processed S3 event"),
        }
    except Exception as e:
        logger.error(f"Lambda handler error: {e}", exc_info=True)
        raise
