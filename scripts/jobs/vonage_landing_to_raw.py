import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, lit, when, concat
from pyspark.sql.types import IntegerType
from pyspark.sql import SparkSession
import boto3
import pyspark.sql.functions as F

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, get_s3_subfolders, PARTITION_KEYS, \
    clean_column_names, get_max_date_partition_value_from_glue_catalogue

s3_client = boto3.client('s3')
sc = SparkContext.getOrCreate()
spark = SparkSession.builder.getOrCreate()
glue_context = GlueContext(sc)

logger = glue_context.get_logger()


def data_source_landing_to_raw(bucket_source, bucket_target, s3_prefix):
    logger.info("bucket_target" + bucket_target)
    logger.info("s3_prefix" + s3_prefix)
    data_source = spark.read.option("multiline", "true").json(bucket_source + "/" + s3_prefix)
    logger.info(f"Retrieved data source from s3 path {bucket_source}/{s3_prefix}")

    latest_import = get_max_date_partition_value_from_glue_catalogue('data-and-insight-raw-zone', 'icaseworks',
                                                                     'import_date')
    logger.info(f"latest_data on raw: {latest_import}")

    latest_data = data_source.filter(F.col("import_date") > latest_import)

    data_frame = clean_column_names(latest_data)
    logger.info("Using Columns: " + str(data_frame.columns))

    date_partition_formatted = data_frame.withColumn("import_month", col("import_month").cast(IntegerType())) \
        .withColumn("import_day", col("import_day").cast(IntegerType())) \
        .withColumn("import_month", when(col("import_month") < 10, concat(lit("0"), col("import_month"))).otherwise(
        col("import_month"))) \
        .withColumn("import_day",
                    when(col("import_day") < 10, concat(lit("0"), col("import_day"))).otherwise(col("import_day")))

    date_partition_formatted.write.mode("append").partitionBy(*PARTITION_KEYS).parquet(bucket_target + "/" + s3_prefix)


args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
s3_prefix = get_glue_env_var('s3_prefix', '')
s3_bucket_source = get_glue_env_var('s3_bucket_source', '')

data_source_landing_to_raw("s3://" + s3_bucket_source, "s3://" + s3_bucket_target, s3_prefix)

job.commit()
