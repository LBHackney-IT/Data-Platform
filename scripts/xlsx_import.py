import pandas as pd
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext

from helpers import get_glue_env_var, convert_pandas_df_to_spark_dynamic_df, PARTITION_KEYS

s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
header_row_number = get_glue_env_var('header_row_number', 0)
worksheet_name = get_glue_env_var('worksheet_name', '')

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

panada_df = pd.read_excel(
    s3_bucket_source,
    engine='openpyxl',
    skiprows=range(0, int(header_row_number)-1),
    sheet_name=worksheet_name
)

# Cast everything as string
panada_df = panada_df.astype(str)

# Replace missing column names with valid names
panada_df.columns = ["column" + str(i) if a.strip() == "" else a.strip()
                     for i, a in enumerate(panada_df.columns)]

# Strip training spaces from data cells
panada_df = panada_df.apply(lambda x:  x.str.strip() if type(x) is str else x)

# Replace any nulls with empty strings
panada_df.fillna(value='', inplace=True)

sqlContext = SQLContext(sc)

spark_df = convert_pandas_df_to_spark_dynamic_df(sql_context=sqlContext, panadas_df=panada_df)

frame = DynamicFrame.fromDF(spark_df, glueContext, "DataFrame")

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
