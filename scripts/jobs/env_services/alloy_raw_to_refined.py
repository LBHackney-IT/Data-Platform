import datetime
import json
import sys

import boto3
import botocore
import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import clean_column_names, get_glue_env_var


def get_table_names(glue_database, glue_table_prefix, region_name="eu-west-2"):
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


def add_refined_date_cols(daily_df):
    now = datetime.datetime.now()
    refined_year = str(now.year)
    refined_month = str(now.month).zfill(2)
    refined_day = str(now.day).zfill(2)
    refined_date = refined_year + refined_month + refined_day

    daily_df_with_refined_cols = (
        daily_df.withColumn("refined_year", F.lit(refined_year))
        .withColumn("refined_month", F.lit(refined_month))
        .withColumn("refined_day", F.lit(refined_day))
        .withColumn("refined_date", F.lit(refined_date))
    )

    return daily_df_with_refined_cols


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
    s3_refined_zone_bucket = get_glue_env_var("s3_refined_zone_bucket", "")
    s3_mapping_bucket = get_glue_env_var("s3_mapping_bucket", "")
    s3_mapping_location = get_glue_env_var("s3_mapping_location", "")
    s3_target_prefix = get_glue_env_var("s3_target_prefix", "")

    table_names = get_table_names(glue_database, glue_table_prefix)

    logger.info(f"found {len(table_names)}, creating trusted frames")

    for table in table_names:
        logger.info(f"creating dyf for {table}")
        daily_df = glueContext.create_dynamic_frame.from_catalog(
            database=glue_database,
            table_name=table,
            transformation_ctx=f"datasource_{table}",
        )

        mapping_file_key = f"{s3_mapping_location}{table}.json"

        try:
            s3.Object(s3_mapping_bucket, mapping_file_key).load()
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                logger.info(f"No mapping file for {table} found, {e.response}")
            else:
                logger.info(f"Error retrieving mapping file {e.response}")
        else:
            obj = s3.Object(s3_mapping_bucket, mapping_file_key).get()
            mapping = json.loads(obj["Body"].read())
            daily_df = rename_columns(daily_df, mapping)

        daily_df = clean_column_names(daily_df.toDF())

        daily_df_with_refined_cols = add_refined_date_cols(daily_df)

        outputDynamicFrame = DynamicFrame.fromDF(
            daily_df_with_refined_cols, glueContext, "outputDynamicFrame"
        )

        target_path = f"s3://{s3_refined_zone_bucket}/{s3_target_prefix}{table}"
        datasink = glueContext.write_dynamic_frame.from_options(
            frame=outputDynamicFrame,
            connection_type="s3",
            format="parquet",
            connection_options={
                "path": target_path,
                "partitionKeys": [
                    "refined_year",
                    "refined_month",
                    "refined_day",
                    "refined_date",
                ],
            },
            transformation_ctx=f"write_{table}",
        )

    job.commit()
