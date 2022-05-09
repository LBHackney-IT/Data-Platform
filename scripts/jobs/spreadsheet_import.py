import sys
import os
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext

from helpers.helpers import get_glue_env_var, add_import_time_columns, clean_column_names, PARTITION_KEYS


def create_dataframe_from_xlsx():
    dataframe = sql_context.read.format("com.crealytics.spark.excel") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .option("dataAddress", f'\'{worksheet_name}\'!A{int(header_row_number)}') \
        .load(s3_bucket_source)
    dataframe = clean_and_enhance_dataframe(dataframe)
    return dataframe


def create_dataframe_from_csv():
    dataframe = sql_context.read.format("csv").option("header", "true").load(s3_bucket_source)
    dataframe = clean_and_enhance_dataframe(dataframe)
    return dataframe


def clean_and_enhance_dataframe(dataframe):
    dataframe = clean_column_names(dataframe)
    # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
    dataframe = dataframe.na.drop('all')
    dataframe = add_import_time_columns(dataframe)
    return dataframe


def infer_file_type(file_path):
    file_extension = os.path.splitext(file_path)[1]
    return file_extension.lower().lstrip(".")


def load_file(file_extension):
    if file_extension == "xlsx":
        dataframe = create_dataframe_from_xlsx()
    elif file_extension == "csv":
        dataframe = create_dataframe_from_csv()

    return dataframe


if __name__ == "__main__":
    s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    header_row_number = get_glue_env_var('header_row_number', 0)
    worksheet_name = get_glue_env_var('worksheet_name', '')

    ## @params: [JOB_NAME]
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    sql_context = SQLContext(sc)

    file_type = infer_file_type(s3_bucket_source)
    df = load_file(file_type)

    frame = DynamicFrame.fromDF(df, glueContext, "DataFrame")

    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=frame,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": s3_bucket_target,
            "partitionKeys": PARTITION_KEYS
        },
        transformation_ctx="parquet_data"
    )

    job.commit()
