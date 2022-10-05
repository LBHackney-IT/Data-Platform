import json
import sys

import boto3
import botocore
import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from scripts.helpers.helpers import get_glue_env_var


def get_table_names(glue_database, glue_table_prefix, region_name="eu-west=2"):
    """
    Returns a list of tables from a glue catalog database that begin with a common prefix
    """
    glue_client = boto3.client("glue", region_name=region_name)
    response = glue_client.get_tables(
        DatabaseName=glue_database, Expression=f"^{glue_table_prefix}*"
    )

    table_names = [t["Name"] for t in response["TableList"]]
    return table_names


def rename_columns(df, columns):
    """
    Renames columns of a dataframe as described by a dictionary of "old_name": "new_name"
    """
    if isinstance(columns, dict):
        return df.select(
            *[
                F.col(col_name).alias(columns.get(col_name, col_name))
                for col_name in df.columns
            ]
        )
    else:
        raise ValueError(
            "'columns' should be a dict, like {'old_name_1': 'new_name_1', 'old_name_2': 'new_name_2'}"
        )


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session

    logger = glueContext.get_logger()

    s3 = boto3.resource("s3")

    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    glue_database = get_glue_env_var("glue_database", "")
    glue_table_prefix = get_glue_env_var("glue_table_prefix", "")
    s3_raw_zone_bucket = get_glue_env_var("s3_raw_zone_bucket", "")
    s3_mapping_location = get_glue_env_var("s3_mapping_location", "")
    s3_downloads_prefix = get_glue_env_var("s3_downloads_prefix", "")
    redshift_database = get_glue_env_var("redshift_database", "")

    table_names = get_table_names(glue_database, glue_table_prefix)

    for table in table_names:
        daily_df = glueContext.create_dynamic_frame.from_catalog(
            database=glue_database,
            table_name=table,
            transformation_ctx=f"datasource_{table}",
        )

        mapping_file_key = f"{s3_mapping_location}{table}.json"

        try:
            s3.Object(s3_mapping_location, mapping_file_key).load()
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                logger.info(f"No mapping file for {table} found, {e.response}")
            else:
                logger.info(f"Error retrieving mapping file {e.response}")
        else:
            obj = s3.Object(s3_mapping_location, mapping_file_key).get()
            mapping = json.loads(obj["Body"].read())
            daily_df = rename_columns(daily_df, mapping)

        glueContext.write_dynamic_frame.from_jdbc_conf(
            frame=daily_df,
            catalog_connection="redshift",
            connection_options={"dbtable": table, "database": redshift_database},
            redshift_tmp_dir="s3://redshift_tmp_dir_path",
        )

    job.commit()
