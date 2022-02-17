import boto3
import sys
import re
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

from helpers.helpers import get_glue_env_var

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

source_catalog_database = get_glue_env_var('source_data_database', '')
source_catalog_table    = get_glue_env_var('source_data_catalogue_table', '')
s3_bucket_target = get_glue_env_var('s3_target', '')

source_ddf = glueContext.create_dynamic_frame.from_catalog(
    database=source_catalog_database,
    table_name=source_catalog_table,
    transformation_ctx="parquetData",
)

apply_mapping = ApplyMapping.apply(
    frame=source_ddf,
    mappings=[
        ("ref", "string", "ref", "string"),
        ("amount", "decimal", "amount", "decimal"),
        ("dhp_ind", "short", "dhp_ind", "short"),
        ("cheque_num", "int", "cheque_num", "int"),
        ("pay_type", "string", "pay_type", "string"),
        ("bank_acc", "int", "bank_acc", "int"),
        ("prop_ref", "string", "prop_ref", "string"),
        ("authority_id", "short", "authority_id", "short"),
        ("seq", "short", "seq", "short"),
    ],
    transformation_ctx="apply_mapping",
)

target_ddf = glueContext.write_dynamic_frame.from_options(
    frame=apply_mapping,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_bucket_target
    },
    transformation_ctx="parquetData",
)

job.commit()