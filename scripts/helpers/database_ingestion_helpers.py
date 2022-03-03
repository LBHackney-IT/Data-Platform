import boto3

def get_all_database_tables(glue_client, source_catalog_database):
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

    return all_tables


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

