import logging
import time
from typing import Dict, List, Optional

import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run_query_on_athena(
    query: str,
    database_name: str,
    output_location: str,
    fetch_results: bool = True,
) -> Optional[List[Dict]]:
    """
    Executes a SQL query on an AWS Athena database, supporting queries across multiple databases by specifying database names directly within the SQL.

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

    Returns:
    --------
    Optional[List[Dict]]
        Returns a list of dictionaries representing the query results if fetch_results is True.
        Each dictionary corresponds to a row in the result set, with column names as keys.
        Returns None if fetch_results is False or if the query fails and the table does not exist.
    """
    # Create a boto3 Athena client using IAM roles/credentials configured in the environment
    client = boto3.client("athena")

    # Start query execution
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": database_name},
        ResultConfiguration={"OutputLocation": output_location},
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
