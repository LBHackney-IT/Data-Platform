import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext

import pandas as pd

def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

## @params: [JOB_NAME]
s3_bucket_source= get_glue_env_var('s3_bucket_source', '')
s3_bucket_target= get_glue_env_var('s3_bucket_target', '')


args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# panada_df = pd.read_excel('s3://dataplatform-el-raw-zone/spreadsheet-in/pets.xls')
panada_df = pd.read_excel(s3_bucket_source, engine='openpyxl')

sqlContext = SQLContext(sc)

spark_df = sqlContext.createDataFrame(panada_df)

frame = DynamicFrame.fromDF(spark_df, glueContext, "DataFrame")

DataSink0 = glueContext.write_dynamic_frame.from_options(
    frame = frame,
    connection_type = "s3",
    format = "parquet",
    connection_options = {"path": s3_bucket_target, "partitionKeys": []},
    transformation_ctx = "DataSink0"
)

job.commit()