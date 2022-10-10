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
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions



args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table    = get_glue_env_var('source_catalog_table', '')
source_catalog_table2    = get_glue_env_var('source_catalog_table2', '')
cleaned_locations_s3_bucket_target = get_glue_env_var('cleaned_covid_locations_s3_bucket_target', '')

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


# logger.info('Fetch Source Data')
source_data = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
) 

df = source_data.toDF()
df = get_latest_partitions(df)

df.printSchema()
df.show(vertical=False, n=5)

# rename a column

df2 = df.withColumnRenamed('location', 'country') 

#cast string to date

df2 = df2.withColumn('last_observation_date', F.to_timestamp('last_observation_date', 'yyyy-MM-dd'))

# add the second dataset

source_data2 = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table2,
) 

df3 = source_data2.toDF()
df3 = get_latest_partitions(df3)


# join the data

merged_data = df2.join(df3, df2.iso_code == df3.iso_code,how='left')


cleanedDataframe = DynamicFrame.fromDF(merged_data, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_locations_s3_bucket_target,"partitionKeys": ["import_year", "import_month", "import_day", "import_date"]},
    transformation_ctx="parquetData")
job.commit()
