import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col, trim, when, max, trim
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import map_repair_priority, clean_column_names


def clean_avonline_repairs(dataframe):
    # convert contact details to title case
    dataframe = dataframe.withColumn('contact_information',
                       F.initcap(F.col('contact_information')))
    return dataframe


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    source_catalog_table = get_glue_env_var('source_catalog_table', '')
    cleaned_repairs_s3_bucket_target = get_glue_env_var(
        'cleaned_repairs_s3_bucket_target', '')

    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    logger.info('Fetch Source Data')

    source_data = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table
    )

    df = source_data.toDF()
    df = get_latest_partitions(df)
    df2 = clean_column_names(df)


    logger.info('convert timestamp and date columns to datetime / date field types')
    df2 = df2.withColumn('timestamp', F.to_timestamp(
        "timestamp", "dd/MM/yyyy HH:mm:ss"))
    df2 = df2.withColumn('date_temp_order_reference', F.to_date(
        'date_temp_order_reference', "dd/MM/yyyy"))

    # convert contact info to title case
    df2 = clean_avonline_repairs(df2)

    # split out phone number from contact field
    df2 = df2.withColumn("phone_1", F.regexp_extract(
        "contact_information", "(\d+)", 0))

    # keep name only from contact field
    df2 = df2.withColumn("name_full", F.regexp_extract(
        "contact_information", "[a-zA-Z]+(?:\s[a-zA-Z]+)*", 0))

    # add new data source column to specify which repairs sheet the repair came from
    df2 = df2.withColumn('data_source', F.lit('Avonline'))

    # rename column names
    df2 = df2.withColumnRenamed('email_address', 'email_staff') \
        .withColumnRenamed('date_temp_order_reference', 'temp_order_number_date') \
        .withColumnRenamed('time_temp_order_reference', 'temp_order_number_time') \
        .withColumnRenamed('temporary_order_number_if_required', 'temp_order_number_full') \
        .withColumnRenamed('call_out_sors', 'sor') \
        .withColumnRenamed('priority_code', 'work_priority_description') \
        .withColumnRenamed('notes_and_information', 'notes') \
        .withColumnRenamed('timestamp', 'datetime_raised')

    # drop columns not needed
    df2 = df2.drop('contact_information')

    df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

    # write data to S3 bucket
    cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=cleanedDataframe,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="parquetData")
    job.commit()
