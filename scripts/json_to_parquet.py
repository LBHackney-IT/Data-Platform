import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from helpers import get_glue_env_var, get_latest_partitions


s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

DataSource0 = glueContext.create_dynamic_frame.from_options(
    format_options = {"jsonPath":"","multiline":False},
    connection_type = "s3",
    format = "json",
    connection_options = {"paths": [s3_bucket_source], "recurse":True},
    transformation_ctx = "DataSource0"
)

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=DataSource0,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_bucket_target
    },
    transformation_ctx="parquetData"
)

job.commit()
