import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SparkSession

from helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS, parse_json_into_dataframe


if __name__ == "__main__":

    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    source_catalog_table = get_glue_env_var('source_catalog_table', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

    sc = SparkContext.getOrCreate()
    spark = SparkSession.builder.getOrCreate()
    glueContext = GlueContext(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    source_data = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
    )

    df = source_data.toDF()
    df = get_latest_partitions(df)
    df = parse_json_into_dataframe(spark=spark, column='contacts', dataframe=df)

    cleanedDataframe = DynamicFrame.fromDF(df, glueContext, "cleanedDataframe")
    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=cleanedDataframe,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": s3_bucket_target, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="parquetData")
    job.commit()
