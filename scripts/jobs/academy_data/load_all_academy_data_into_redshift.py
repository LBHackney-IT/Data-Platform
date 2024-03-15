import time
from datetime import datetime
from typing import List, Dict, Any, Optional
import boto3
from scripts.helpers.helpers import get_secret_dict, get_glue_env_var
from scripts.helpers.redshift_helpers import rs_command
import redshift_connector

environment = get_glue_env_var("environment")
role_arn = get_glue_env_var("role_arn")
base_s3_url = get_glue_env_var("base_s3_url")

def rs_command(query: str, fetch_results: bool = False, allow_commit: bool = True, database_name: str = 'academy') -> Optional[List[Dict]]:
   """Executes a SQL query against a Redshift database, optionally fetching results.

   Args:
       query (str): The SQL query to execute.
       fetch_results (bool): Whether to fetch and return the query results (default False).
       allow_commit (bool): Whether to allow committing the transaction (default True).
       database_name: Name of the database to connect to, defaults to 'academy'.

   Returns:
       Optional[List[Dict]]: A list of dictionaries representing rows returned by the query if fetch_results is True; otherwise None.
   """
   creds = get_secret_dict('/data-and-insight/redshift-serverless-connection', 'eu-west-2')
   try:
       # Connects to Redshift cluster using AWS credentials
       conn = redshift_connector.connect(
           host=creds['host'],
           database=database_name,
           user=creds['user'],
           password=creds['password']
       )
       
       # autocommit is off by default. 
       if allow_commit:
           # Add this line to handle commands like CREATE EXTERNAL TABLE
           conn.autocommit = True

       cursor = conn.cursor()

       # Execute the query
       cursor.execute(query)
       
       # Fetch the results if required
       if fetch_results:
           result = cursor.fetchall()
           return [dict(row) for row in result] if result else []
       elif allow_commit:
           # Commit the transaction only if allowed and needed
           conn.commit()

   except redshift_connector.Error as e:
       raise e
   finally:
       if cursor:
           cursor.close()
       if conn:
           conn.close()
   return None  # Return None if fetch_results is False or if there's an error

def get_all_tables(glue_client: Any, database_name: str, pattern: str = '') -> List[Dict]:
    """Retrieve all table metadata from Glue catalog for a specific database."""
    tables = []
    paginator = glue_client.get_paginator('get_tables') # Without paginator, only get 100 tables
    for page in paginator.paginate(DatabaseName=database_name):
        for table in page['TableList']:
            if pattern in table['Name']:
                tables.append(table)
    return tables

def truncate_table(schema: str, table_name: str) -> str:
    """Generate SQL to truncate a table."""
    return f"TRUNCATE TABLE {schema}.{table_name};"

def copy_command(schema: str, table_name: str, s3_location: str, iam_role: str) -> str:
    """Generate SQL for the COPY command."""
    return f"""
    COPY {schema}.{table_name}
    FROM '{s3_location}'
    IAM_ROLE '{iam_role}'
    FORMAT AS PARQUET;
    """

def create_table_sql(schema: str, table_name: str, columns: List[Dict[str, str]]) -> str:
    """Generate SQL to create a Redshift table matching the Parquet file structure."""
    type_mapping = {
        'int': 'INTEGER',
        'string': 'VARCHAR(65535)',
        'decimal(3,0)': 'DECIMAL(3,0)',
        'timestamp': 'TIMESTAMP',
        'double': 'DOUBLE PRECISION'
    }
    column_definitions = ', '.join(
        f"{col['Name']} {type_mapping.get(col['Type'], col['Type'])}"
        for col in columns
    )
    return f"CREATE TABLE {schema}.{table_name} ({column_definitions});"

def get_s3_location(glue_table_name: str, base_s3_url: str) -> str:
    """Generate S3 location for today based on the table name."""
    today = datetime.today() 
    year, month, day = today.year, str(today.month).zfill(2), str(today.day).zfill(2)
    return f"{base_s3_url}{glue_table_name}/import_year={year}/import_month={month}/import_day={day}/import_date={year}{month}{day}/"

def process_load_tables(schema: str, catalog: str, table_mapping: Dict[str, str], iam_role: str, base_s3_url: str) -> None:
    """Main function to process and load tables."""
    creds = get_secret_dict('/data-and-insight/database-migration-access-id-and-secret-key', 'eu-west-2') 
    glue_client = boto3.client('glue', region_name='eu-west-2', aws_access_key_id=creds['accessKeyId'], aws_secret_access_key=creds['secretAccessKey'])

    for original_pattern, new_prefix in table_mapping.items():
        for table in get_all_tables(glue_client, catalog, original_pattern):
            new_table_name = table['Name'].replace(original_pattern, new_prefix)
            create_sql = create_table_sql(schema, new_table_name, table['StorageDescriptor']['Columns'])
            # print(create_sql)  #  print statements are for debugging

            try:
                rs_command(create_sql, fetch_results=False, allow_commit=True)
                print(f"Table {schema}.{new_table_name} created successfully.")
            except Exception as e:
                if 'already exists' in str(e):
                    print(f"Table {new_table_name} already exists.")
                else:
                    print(f"Failed to create table {new_table_name}: {e}")
                    raise e

            truncate_sql = truncate_table(schema, new_table_name)
            rs_command(truncate_sql, fetch_results=False, allow_commit=True)
            print(f"Table {schema}.{new_table_name} truncated successfully.")

            s3_location = get_s3_location(table['Name'], base_s3_url)
            copy_sql = copy_command(schema, new_table_name, s3_location, iam_role)
            # print(copy_sql) #  print statements are for debugging
            try:
                rs_command(copy_sql, fetch_results=False, allow_commit=True)
                print(f"Data for {datetime.today().strftime('%Y%m%d')} copied successfully into table {new_table_name}.")
            except Exception as e:
                print(f"Failed to copy data into table {schema}.{new_table_name}: {e}")

            time.sleep(1)  # Sleep to mitigate risk of overwhelming the cluster

def main():
    # for all tables under ctax
    process_load_tables(
        schema='ctax', # Redshift schema
        catalog='revenues-raw-zone', # Glue catalog database
        # map the table names in Glue catalog to names in Redshift
        table_mapping= {
            'lbhaliverbviews_core_ct': 'ct',
            'lbhaliverbviews_core_sy': 'sy'
        },
        iam_role=role_arn,
        base_s3_url = base_s3_url
    )

    # for all tables under nndr
    process_load_tables(
        schema='nndr', 
        catalog='revenues-raw-zone',
        table_mapping= {
            'lbhaliverbviews_core_nr': 'nr',
            'lbhaliverbviews_core_sy': 'sy'
        },
        iam_role=role_arn,
        base_s3_url = base_s3_url
    )

    # for all tables under hben
    process_load_tables(
        schema='hben', 
        catalog='revenues-raw-zone', 
        table_mapping= {
            'lbhaliverbviews_core_sy': 'sy',
            'lbhaliverbviews_core_ctaccount': 'ctaccount',
            'lbhaliverbviews_core_ctnotice': 'ctnotice',
            'lbhaliverbviews_core_ctoccupation': 'ctoccupation',
            'lbhaliverbviews_core_ctproperty': 'ctproperty',
            'lbhaliverbviews_core_cttransaction': 'cttransaction',
        },
        iam_role=role_arn,
        base_s3_url = base_s3_url
    )
    process_load_tables(
        schema='hben', 
        catalog='bens-housing-needs-raw-zone', 
        table_mapping= {
            'lbhaliverbviews_core_hb': 'hb',
        },
        iam_role=role_arn,
        base_s3_url = f"s3://dataplatform-{environment}-raw-zone/benefits-housing-needs/" # note the path change
    )

if __name__ == "__main__":
    main()