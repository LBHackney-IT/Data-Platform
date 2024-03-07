import time
from datetime import datetime
from typing import List, Dict, Any
from utils import rs_command, get_secret
import boto3


def get_all_tables(glue_client: Any, database_name: str, pattern: str = '') -> List[Dict]:
    """Retrieve all table metadata from Glue catalog for a specific database."""
    tables = []
    paginator = glue_client.get_paginator('get_tables')
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

def main(schema: str, catalog: str, table_mapping: Dict[str, str], iam_role: str, base_s3_url: str) -> None:
    """Main function to process and load tables."""
    creds = get_secret('data-and-insight', 'eu-west-2') # this need to change to the new role "database_migration" access id and access key;
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

if __name__ == "__main__":
    # for all tables under ctax
    main(
        schema='ctax', # Redshift schema
        catalog='revenues-raw-zone', # Glue catalog database
        # map the table names in Glue catalog to names in Redshift
        table_mapping= {
            'lbhaliverbviews_core_ct': 'ct',
            'lbhaliverbviews_core_sy': 'sy'
        },
        iam_role='arn:aws:iam::120038763019:role/dataplatform-stg-redshift-serverless-role',
        base_s3_url = "s3://dataplatform-stg-raw-zone/revenues/"
    )

    # for all tables under nndr
    main(
        schema='nndr', # Redshift schema
        catalog='revenues-raw-zone', # Glue catalog database
        # map the table names in Glue catalog to names in Redshift
        table_mapping= {
            'lbhaliverbviews_core_nr': 'nr',
            'lbhaliverbviews_core_sy': 'sy'
        },
        iam_role='arn:aws:iam::120038763019:role/dataplatform-stg-redshift-serverless-role',
        base_s3_url = "s3://dataplatform-stg-raw-zone/revenues/"
    )

    # for all tables under hben
    main(
        schema='hben', # Redshift schema
        catalog='revenues-raw-zone', # Glue catalog database
        # map the table names in Glue catalog to names in Redshift
        table_mapping= {
            'lbhaliverbviews_core_sy': 'sy',
            'lbhaliverbviews_core_ctaccount': 'ctaccount',
            'lbhaliverbviews_core_ctnotice': 'ctnotice',
            'lbhaliverbviews_core_ctoccupation': 'ctoccupation',
            'lbhaliverbviews_core_ctproperty': 'ctproperty',
            'lbhaliverbviews_core_cttransaction': 'cttransaction',
        },
        iam_role='arn:aws:iam::120038763019:role/dataplatform-stg-redshift-serverless-role',
        base_s3_url = "s3://dataplatform-stg-raw-zone/revenues/"
    )
    main(
        schema='hben', # Redshift schema
        catalog='bens-housing-needs-raw-zone', # Glue catalog database
        # map the table names in Glue catalog to names in Redshift
        table_mapping= {
            'lbhaliverbviews_core_hb': 'hb',
        },
        iam_role='arn:aws:iam::120038763019:role/dataplatform-stg-redshift-serverless-role',
        base_s3_url = "s3://dataplatform-stg-raw-zone/benefits-housing-needs/" # note the path change
    )

