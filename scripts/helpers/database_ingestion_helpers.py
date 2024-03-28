import re
from typing import List, Dict, Optional, Union
from datetime import datetime

def get_all_database_tables(glue_client, source_catalog_database, table_filter_expression=None):
    all_tables = []

    response = glue_client.get_tables(
        DatabaseName=source_catalog_database,
    )
    for table in response['TableList']:
        all_tables.append(table['Name'])

    while 'NextToken' in response.keys():
        response = glue_client.get_tables(
            DatabaseName=source_catalog_database,
            NextToken=response['NextToken']
        )
        for table in response['TableList']:
            all_tables.append(table['Name'])

    if table_filter_expression:
      return get_filtered_tables(all_tables, table_filter_expression)

    return all_tables

def get_filtered_tables(tables, table_filter_expression):
    filtering_pattern = re.compile(table_filter_expression)
    filtered_tables = [table for table in tables if filtering_pattern.match(table)]

    return filtered_tables

def update_table_ingestion_details(
    table_ingestion_details: List[Dict[str, Union[str, int, None]]],
    table_name: str,
    minutes_taken: int,
    error: bool,
    error_details: Optional[str],
    run_datetime: Optional[datetime] = None,
    row_count: Optional[int] = None,
    run_id: Optional[int] = None
) -> List[Dict[str, Union[str, int, None]]]:
    """
    Updates the details of table ingestion by appending a new record to the
    list of ingestion details.

    Parameters:
    - table_ingestion_details: A list of dictionaries with details of table ingestions.
    - table_name: The name of the table.
    - minutes_taken: The number of minutes the ingestion took.
    - error: Boolean indicating if there was an error during ingestion.
    - error_details: Optional string detailing the error if any.
    - run_datetime: Optional datetime when the ingestion run occurred. Defaults to current datetime if not provided.
    - row_count: Optional number of rows ingested.
    - run_id: Optional identifier for the ingestion run.

    Returns:
    - The updated list of table ingestion details.
    """
    if run_datetime is None:
        run_datetime = datetime.now()

    table_ingestion_details.append({
        "table_name": table_name,
        "minutes_taken": minutes_taken,
        "error": error,
        "error_details": str(error_details) if error_details else None,
        "run_datetime": run_datetime.isoformat(),
        "row_count": row_count,
        "run_id": run_id
    })

    return table_ingestion_details


