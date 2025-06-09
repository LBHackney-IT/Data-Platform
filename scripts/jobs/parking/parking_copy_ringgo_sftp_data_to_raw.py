import sys

import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, concat, lit, when
from pyspark.sql.types import IntegerType

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    clean_column_names,
    get_glue_env_var,
    get_latest_partitions,
    get_s3_subfolders,
)

s3_client = boto3.client("s3")
sc = SparkContext.getOrCreate()
spark = SparkSession.builder.getOrCreate()
glue_context = GlueContext(sc)

logger = glue_context.get_logger()


def data_source_landing_to_raw(bucket_source, bucket_target, s3_prefix):
    logger.info("bucket_target" + bucket_target)
    logger.info("s3_prefix" + s3_prefix)
    data_source = spark.read.option("header", "true").csv(
        bucket_source + "/" + s3_prefix
    )
    latest_data = get_latest_partitions(data_source)
    logger.info(f"latest_data: {latest_data}")

    logger.info(f"Retrieved data source from s3 path {bucket_source}/{s3_prefix}")

    data_frame = clean_column_names(latest_data)
    logger.info("Using Columns: " + str(data_frame.columns))

    date_partition_formatted = (
        data_frame.withColumn("import_month", col("import_month").cast(IntegerType()))
        .withColumn("import_day", col("import_day").cast(IntegerType()))
        .withColumn(
            "import_month",
            when(
                col("import_month") < 10, concat(lit("0"), col("import_month"))
            ).otherwise(col("import_month")),
        )
        .withColumn(
            "import_day",
            when(col("import_day") < 10, concat(lit("0"), col("import_day"))).otherwise(
                col("import_day")
            ),
        )
    )

    date_partition_formatted.write.mode("append").partitionBy(*PARTITION_KEYS).parquet(
        bucket_target + "/" + s3_prefix
    )


args = getResolvedOptions(sys.argv, ["JOB_NAME"])

job = Job(glue_context)
job.init(args["JOB_NAME"], args)

s3_bucket_target = get_glue_env_var("s3_bucket_target", "")
s3_prefix = get_glue_env_var("s3_prefix", "")
s3_bucket_source = get_glue_env_var("s3_bucket_source", "")

data_source_landing_to_raw(
    "s3://" + s3_bucket_source, "s3://" + s3_bucket_target, s3_prefix
)

job.commit()
