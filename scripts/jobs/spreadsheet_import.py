import sys
import os
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, clean_column_names, PARTITION_KEYS


def create_dataframe_from_xlsx(sql_context, worksheet_name, header_row_number, file_path):
    dataframe = sql_context.read.format("com.crealytics.spark.excel") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .option("dataAddress", f'\'{worksheet_name}\'!A{int(header_row_number)}') \
        .option("maxRowsInMemory", 100) \
        .option("maxByteArraySize", 500000000) \
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

    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    from pyspark.conf import SparkConf
    conf = SparkConf()
    conf.set("spark.sql.legacy.timeParserPolicy", "CORRECTED")

    sc = SparkContext(conf=conf)
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    file_type = infer_file_type(s3_bucket_source)
    # Use glueContext.spark_session instead of SQLContext(sc) for PySpark 3.x+ compatibility
    df = load_file(file_type, spark, get_glue_env_var('worksheet_name', ''), get_glue_env_var('header_row_number', 0), s3_bucket_source)

    df.write.mode("append").partitionBy(*PARTITION_KEYS).parquet(s3_bucket_target)

    job.commit()
