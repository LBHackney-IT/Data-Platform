import boto3
import re

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
      return filtered_tables(all_tables, table_filter_expression)

    return all_tables

def filtered_tables(tables, table_filter_expression):
    filtering_pattern = re.compile(table_filter_expression)
    filtered_tables = [table for table in tables if filtering_pattern.match(table)]

    return filtered_tables

def update_table_ingestion_details(table_ingestion_details, table_name, minutes_taken, error, error_details):
    table_ingestion_details.append(
        {
            "table_name": table_name,
            "minutes_taken": minutes_taken,
            "error": error,
            "error_details": str(error_details)
        }
    )

    return table_ingestion_details

