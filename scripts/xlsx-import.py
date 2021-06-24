import gspread
import pandas as pd
import sys
import boto3
import base64
import logging
import json
import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext
from pyspark.sql import functions as f


def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

## @params: [JOB_NAME]
s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
header_row_number = get_glue_env_var('header_row_number', 0)
worksheet_name = get_glue_env_var('worksheet_name', '')
logger = glueContext.get_logger()

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

panada_df = pd.read_excel(
    s3_bucket_source,
    engine='openpyxl',
    skiprows=range(0, int(header_row_number)),
    sheet_name=worksheet_name
)

# Replace missing column names with valid names
panada_df.columns = ["column" + str(i) if a.strip() == "" else a.strip()
                     for i, a in enumerate(panada_df.columns)]

# Strip trainling spaces from data cells
panada_df = panada_df.apply(lambda x:  x.str.strip() if type(x) is str else x)

# Replace any nulls with empty strings
panada_df.fillna(value='', inplace=True)

sqlContext = SQLContext(sc)

now = datetime.datetime.now()
# Convert to SparkDynamicDataFrame
spark_df = sqlContext.createDataFrame(panada_df)
spark_df = spark_df.coalesce(1)
spark_df = spark_df.withColumn('import_date', f.current_timestamp())
spark_df = spark_df.withColumn('import_timestamp', f.lit(str(now.timestamp())))
spark_df = spark_df.withColumn('import_year', f.lit(str(now.year)))
spark_df = spark_df.withColumn('import_month', f.lit(str(now.month).zfill(2)))
spark_df = spark_df.withColumn('import_day', f.lit(str(now.day).zfill(2)))


frame = DynamicFrame.fromDF(spark_df, glueContext, "DataFrame")

parquet_data = glueContext.write_dynamic_frame.from_options(
    frame=frame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": s3_bucket_target, "partitionKeys": [
        'import_year', 'import_month', 'import_day']},
    transformation_ctx="parquet_data"
)

job.commit()


# s3://dataplatform-el-glue-temp-storage/
