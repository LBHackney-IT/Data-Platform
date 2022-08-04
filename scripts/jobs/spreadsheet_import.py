import sys
import os
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, clean_column_names, PARTITION_KEYS


def create_dataframe_from_xlsx(sql_context, worksheet_name, header_row_number, file_path):
    dataframe = sql_context.read.format("com.crealytics.spark.excel") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .option("dataAddress", f'\'{worksheet_name}\'!A{int(header_row_number)}') \
        .load(file_path)
    dataframe = clean_and_enhance_dataframe(dataframe)
    return dataframe


def create_dataframe_from_csv(sql_context, file_path):
    dataframe = sql_context.read.format("csv").option("header", "true").load(file_path)
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


def load_file(file_extension, sql_context, worksheet_name, header_row_number, file_path):
    if file_extension == "xlsx":
        dataframe = create_dataframe_from_xlsx(sql_context, worksheet_name, header_row_number, file_path)
    elif file_extension == "csv":
        dataframe = create_dataframe_from_csv(sql_context, file_path)

    return dataframe


if __name__ == "__main__":
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    s3_bucket_source = get_glue_env_var('s3_bucket_source', '')

    ## @params: [JOB_NAME]
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    file_type = infer_file_type(s3_bucket_source)
    df = load_file(file_type, SQLContext(sc), get_glue_env_var('worksheet_name', ''), get_glue_env_var('header_row_number', 0), s3_bucket_source)

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
