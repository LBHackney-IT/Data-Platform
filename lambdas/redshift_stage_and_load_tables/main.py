import os

import boto3

redshift_data_client = boto3.client("redshift-data")


def read_sql_from_file(file_path, params):
    with open(file_path, "r") as f:
        sql_template = f.read()
    return sql_template.format(**params)


def start_sql_execution(cluster_id, database, user, sql):
    response = redshift_data_client.execute_statement(
        ClusterIdentifier=cluster_id,
        Database=database,
        DbUser=user,
        Sql=sql,
        WithEvent=True,
    )

    return response["Id"]


def lambda_handler(event, context):
    cluster_id = os.environ["REDSHIFT_CLUSTER_ID"]
    redshift_database = os.environ["REDSHIFT_DBNAME"]
    user = os.environ["REDSHIFT_USER"]
    iam_role = os.environ["REDSHIFT_IAM_ROLE"]
    source_bucket = os.environ["SOURCE_BUCKET"]
    schema_name = os.environ["SCHEMA_NAME"]
    sql_file = os.environ["SQL_FILE"]

    import_year = event["year"]
    import_month = event["month"]
    import_day = event["day"]
    import_date = event["date"]
    source_database = event["database"]

    query_ids = []

    for table in event["tables"]:
        s3_path = f"s3://{source_bucket}/{source_database}/{table}/{import_year}/{import_month}/{import_day}/{import_date}/"

        params = {
            "schema_name": schema_name,
            "table_name": table,
            "s3_path": s3_path,
            "iam_role": iam_role,
        }

        sql = read_sql_from_file(sql_file, params)

        query_id = start_sql_execution(cluster_id, redshift_database, user, sql)
        query_ids.append(query_id)

    return {
        "statusCode": 200,
        "body": "Started Redshift data staging and load for all tables!",
        "query_ids": query_ids,
    }
