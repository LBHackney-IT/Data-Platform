import logging
import re
import time
from datetime import datetime
from typing import Dict, List, Optional

import boto3

# from urllib.parse import urlparse


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def refined_zone_kms_key_by_environment(environment: str) -> str:
    """
    Returns the appropriate KMS key ARN based on the environment ('stg' or 'prod').
    stg kms key alias: dataplatform-stg-s3-refined-zone
    prod kms key alias : dataplatform-prod-s3-refined-zone
    """
    kms_keys = {
        "stg": "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21",
        "prod": "arn:aws:kms:eu-west-2:365719730767:key/756fa17e-b90d-4445-a7f2-8e07ca550bd0",
    }
    return kms_keys.get(environment, None)


def run_query_on_athena(
    query: str,
    database_name: str,
    output_location: str,
    fetch_results: bool = True,
    kms_key: str = None,
) -> Optional[List[Dict]]:
    """
    Executes a SQL query on an Athena database, supporting queries across multiple databases by specifying database names directly within the SQL.

    Parameters:
    -----------
    query : str
        The SQL query string to be executed on the Athena database.
    database_name : str
        The name of the Athena database where the query will be executed.
    output_location : str
        The location where the query results (default cache csv files) will be stored.
    fetch_results : bool, optional
        A flag to indicate whether to fetch the query results. Default is True.
    kms_key: str, optional
        The KMS key ARN to use for encrypting the query results. Default is None (i.e. Athena Storage kms key).

    Returns:
    --------
    Optional[List[Dict]]
        Returns a list of dictionaries representing the query results if fetch_results is True.
        Each dictionary corresponds to a row in the result set, with column names as keys.
        Returns None if fetch_results is False or if the query fails and the table does not exist.

        Further processing: For the returned "results", it can be converted to a pandas DataFrame using the following code:
        ```
        import pandas as pd
        df = pd.DataFrame(results)
        ```
    """
    # Create a boto3 Athena client using IAM roles/credentials configured in the environment
    client = boto3.client("athena")

    # Define the ResultConfiguration with optional encryption
    result_configuration = {"OutputLocation": output_location}

    if kms_key:
        result_configuration["EncryptionConfiguration"] = {
            "EncryptionOption": "SSE_KMS",
            "KmsKey": kms_key,
        }

    # Start query execution
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": database_name},
        ResultConfiguration=result_configuration,
    )

    query_execution_id = response["QueryExecutionId"]

    # Wait for the query to complete
    while True:
        response = client.get_query_execution(QueryExecutionId=query_execution_id)
        state = response["QueryExecution"]["Status"]["State"]
        if state in {"SUCCEEDED", "FAILED", "CANCELLED"}:
            logger.info(f"Query execution state: {state}")
            if state != "SUCCEEDED":
                # Handle query failure
                if (
                    state == "FAILED"
                    and "Table does not exist"
                    in response["QueryExecution"]["Status"]["StateChangeReason"]
                ):
                    return None  # Ignore the error if the table does not exist
                raise Exception(
                    f"Query failed with state: {state}, reason: {response['QueryExecution']['Status']['StateChangeReason']}"
                )
            break

        logger.info(f"Current state: {state}, waiting for query to complete...")
        time.sleep(3)  # Wait for 3 seconds before checking again

    # Fetch results if required
    if fetch_results:
        return _fetch_query_results(client, query_execution_id)

    return None


# Internal function to run inside "run_query_on_athena" to fetch query results
def _fetch_query_results(
    client: boto3.client, query_execution_id: str
) -> List[Dict[str, Optional[str]]]:
    """
    Fetches the results of the Athena query.

    Parameters:
    -----------
    client : boto3.client
        The Boto3 Athena client.
    query_execution_id : str
        The unique ID for the query execution.

    Returns:
    --------
    List[Dict[str, Optional[str]]]
        A list of dictionaries representing the query results.
    """
    results = []
    next_token = None

    # Fetch results with pagination
    while True:
        if next_token:
            results_response = client.get_query_results(
                QueryExecutionId=query_execution_id, NextToken=next_token
            )
        else:
            results_response = client.get_query_results(
                QueryExecutionId=query_execution_id
            )

        columns = [
            col["Label"]
            for col in results_response["ResultSet"]["ResultSetMetadata"]["ColumnInfo"]
        ]
        rows = results_response["ResultSet"]["Rows"][
            1:
        ]  # Skip header row for the first page only

        # Handle KeyError: 'VarCharValue' if the column is empty;
        # "Data" is the default key for the row values in Athena
        def _parse_row(row: Dict) -> List[Optional[str]]:
            # Safely get the value for each column, defaulting to None if the key doesn't exist
            return [value.get("VarCharValue", None) for value in row["Data"]]

        # Convert rows into a list of dictionaries
        results.extend([dict(zip(columns, _parse_row(row))) for row in rows])

        # Check if there are more results to fetch
        next_token = results_response.get("NextToken")
        if not next_token:
            break

    return results


def generate_s3_partition(base_s3_url: str, execution_date: datetime = None) -> str:
    """
    Generate S3 partition for the given execution date or for today if no execution date is provided, based on the base URL.

    Parameters:
    -----------
    base_s3_url : str
        The base S3 URL.
    execution_date : datetime, optional
        The execution date from the Airflow task instance. Defaults to None, which uses today's date.

    Returns:
    --------
    str
        The S3 partition path based on the execution date.

    Example:
    --------
    >>> base_url = "s3://my-bucket/my-folder"
    >>> execution_date = datetime(2024, 6, 28)
    >>> generate_s3_partition(base_url, execution_date)
    's3://my-bucket/my-folder/import_year=2024/import_month=06/import_day=28/import_date=20240628/'

    >>> generate_s3_partition(base_url)
    's3://my-bucket/my-folder/import_year=2024/import_month=07/import_day=31/import_date=20240731/'
    """
    if execution_date is None:
        execution_date = datetime.today()
    year, month, day = (
        execution_date.year,
        str(execution_date.month).zfill(2),
        str(execution_date.day).zfill(2),
    )
    return f"{base_s3_url}/import_year={year}/import_month={month}/import_day={day}/import_date={year}{month}{day}/"


def empty_s3_path(
    s3_full_path: str,
):
    """
    Delete all files under a specified S3 full path.

    :param s3_full_path: Full S3 path, e.g., 's3://bucket_name/prefix/to/files/'

    Example usage:
    s3_full_path = "s3://dataplatform-stg-refined-zone/child-fam-services/mosaic/cp_transform/import_year=2024/import_month=07/import_day=01/import_date=20240701/"
    empty_s3_path(s3_full_path) to delete all files under the s3_full_path.
    """
    client = boto3.client("s3")
    # Parse the S3 full path
    match = re.match(r"s3://([^/]+)/(.+)", s3_full_path)
    if not match:
        raise ValueError("Invalid S3 path.")

    bucket_name, prefix = match.groups()

    try:
        # List objects under the specified prefix
        response = client.list_objects_v2(Bucket=bucket_name, Prefix=prefix)

        # Check if there are any files to delete
        if "Contents" not in response:
            logger.info(f"No files found under prefix {prefix}")
            return

        # Extract object keys
        objects_to_delete = [{"Key": obj["Key"]} for obj in response["Contents"]]

        # Delete the objects
        client.delete_objects(Bucket=bucket_name, Delete={"Objects": objects_to_delete})

        logger.info(f"All files under prefix {prefix} have been deleted.")

    except Exception as e:
        logging.error(f"An error occurred: {e}")
        raise


def drop_table(
    database_name: str, table_name: str, s3_temp_path_for_cache: str
) -> None:
    """
    Drops the existing table if it exists in Athena.
    """
    drop_table_query = f"""
    DROP TABLE IF EXISTS `{database_name}`.`{table_name}`;
    """
    run_query_on_athena(
        query=drop_table_query,
        database_name=database_name,
        output_location=s3_temp_path_for_cache,
        fetch_results=False,
    )
    logger.info("Table dropped successfully.")


def empty_s3_partition(s3_table_output_location: str) -> None:
    """
    Empties the S3 partition for the physical data of the execution date if it exists
    to avoid duplicate data in the Athena table when re-reunning the ETL.
    """
    s3_local_for_physical_date = generate_s3_partition(s3_table_output_location)
    empty_s3_path(s3_local_for_physical_date)
    logger.info(f"S3 partition at {s3_local_for_physical_date} emptied successfully.")


def create_or_update_table(
    sql_query_body: str,
    database_name: str,
    table_name: str,
    s3_table_output_location: str,
    s3_temp_path_for_cache: str,
    kms_key: str = None,
) -> None:
    """
    Creates or updates an Athena table using the provided SQL query.
    """
    create_table_header = f"""
    CREATE TABLE "{database_name}"."{table_name}"
    WITH (
        format = 'PARQUET',
        write_compression = 'SNAPPY',
        external_location = '{s3_table_output_location}',
        partitioned_by = ARRAY['import_year', 'import_month', 'import_day', 'import_date']
    ) AS
    """
    full_query_ctas = create_table_header + sql_query_body

    run_query_on_athena(
        query=full_query_ctas,
        database_name=database_name,
        output_location=s3_temp_path_for_cache,
        fetch_results=False,
        kms_key=kms_key,
    )
    logger.info("Table created or updated successfully.")


def repair_table(
    database_name: str, table_name: str, s3_temp_path_for_cache: str
) -> None:
    """
    Runs MSCK REPAIR TABLE command to add partitions.
    """
    repair_table_query = f"""
    MSCK REPAIR TABLE `{database_name}`.`{table_name}`;
    """
    run_query_on_athena(
        query=repair_table_query,
        database_name=database_name,
        output_location=s3_temp_path_for_cache,
        fetch_results=False,
    )
    logger.info("MSCK REPAIR TABLE executed successfully. Partitions added.")


def create_update_table_with_partition(
    environment: str,
    query_on_athena: str,
    table_name: str,
    database_name: str = None,
    s3_table_output_location: str = None,
    s3_temp_path_for_cache: str = None,
    kms_key: str = None,
) -> None:
    """
    Coordinates the dropping, emptying, creating/updating, and repairing of the Athena table with partitions.
    """
    # Set default values if not provided (default values are for the parking ETL)
    if not s3_temp_path_for_cache:
        s3_temp_path_for_cache = (
            f"s3://dataplatform-{environment}-athena-storage/parking/temp"
        )
    if not database_name:
        database_name = f"dataplatform-{environment}-liberator-refined-zone"
    if not s3_table_output_location:
        s3_table_output_location = f"s3://dataplatform-{environment}-refined-zone/parking/liberator/{table_name}"
    if not kms_key:
        kms_key = refined_zone_kms_key_by_environment(environment)

    # Replace protoyped athena query environment variables in query
    query_on_athena = query_on_athena.replace("-stg-", f"-{environment}-").replace(
        "-prod-", f"-{environment}-"
    )
    try:
        drop_table(database_name, table_name, s3_temp_path_for_cache)
        empty_s3_partition(s3_table_output_location)
        create_or_update_table(
            query_on_athena,
            database_name,
            table_name,
            s3_table_output_location,
            s3_temp_path_for_cache,
            kms_key,
        )
        repair_table(database_name, table_name, s3_temp_path_for_cache)
    except Exception as e:
        logger.error(f"An error occurred while executing the query: {e}")


# def read_query_content_from_s3(s3_url: str, table_name: str) -> str:
#     """
#     Reads SQL content from S3, matches the file name with table_name (without .sql),
#     and returns the query string content if a match is found.

#     :param s3_url: The S3 URL where SQL files are stored (e.g., "s3://bucket-name/path/").
#     :param table_name: The target table name to match with file names.
#     :return: The content of the SQL file as a string if a match is found, otherwise None.
#     """
#     # Extract bucket name and path from url
#     parsed_url = urlparse(s3_url)
#     bucket_name = parsed_url.netloc
#     s3_path = parsed_url.path.lstrip("/")

#     s3_client = boto3.client("s3")

#     # List all objects in the given S3 path
#     response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=s3_path)

#     if "Contents" not in response:
#         logger.info(f"No files found in {s3_url}")
#         return None

#     # Iterate over the files in the S3 path
#     for obj in response["Contents"]:
#         file_key = obj["Key"]
#         file_name = file_key.split("/")[-1]

#         # Remove the .sql extension to match with the table name, then get the content
#         if file_name.endswith(".sql"):
#             file_base_name = file_name[:-4]
#             if file_base_name == table_name:
#                 logger.info(f"Matching file found for table name: {table_name}")
#                 sql_file_object = s3_client.get_object(Bucket=bucket_name, Key=file_key)
#                 query_content = sql_file_object["Body"].read().decode("utf-8")
#                 logger.info(f"Query content: {query_content}")
#                 return query_content

#     logger.info(f"No matching file found for table name: {table_name}")
#     return None
