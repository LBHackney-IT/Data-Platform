import sys
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F
from pyspark import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, max
from awsglue.job import Job

from scripts.helpers.helpers import get_glue_env_var, PARTITION_KEYS

glueContext = GlueContext(SparkContext.getOrCreate())
job = Job(glueContext)

def get_latest_partitions(dfa):
   dfa = dfa.where(col('import_year') == dfa.select(max('import_year')).first()[0])
   dfa = dfa.where(col('import_month') == dfa.select(max('import_month')).first()[0])
   dfa = dfa.where(col('import_day') == dfa.select(max('import_day')).first()[0])
   return dfa

source_data_database = get_glue_env_var('source_data_database', '')
source_data_catalogue_table = get_glue_env_var('source_data_catalogue_table', '')
source_uhref_header = get_glue_env_var('source_uhref_header', '')
lookup_database = get_glue_env_var('lookup_database', '')
lookup_catalogue_table = get_glue_env_var('lookup_catalogue_table', '')
target_destination = get_glue_env_var('target_destination', '')

### READ SOURCE DATA
source_ddf = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_data_database,
    table_name=source_data_catalogue_table
)

source_df = source_ddf.toDF()
source_df = get_latest_partitions(source_df)

### READ UHREF/UPRN LOOKUP DATA

uhref_uprn_lookup_ddf = glueContext.create_dynamic_frame.from_catalog(
    name_space=lookup_database,
    table_name=lookup_catalogue_table,
)

uhref_uprn_lookup_df = uhref_uprn_lookup_ddf.toDF()
uhref_uprn_lookup_df = get_latest_partitions(uhref_uprn_lookup_df)
uhref_uprn_lookup_df = uhref_uprn_lookup_df.select(col("ten_property_ref"), col("uprn").cast("string")).where("ten_property_ref IS NOT NULL")
uhref_uprn_lookup_df = uhref_uprn_lookup_df.dropDuplicates(["ten_property_ref"])
uhref_uprn_lookup_df = uhref_uprn_lookup_df.withColumnRenamed("ten_property_ref", source_uhref_header)

# ### JOIN

joined_df = source_df.join(uhref_uprn_lookup_df, source_uhref_header, "left")

# ### WRITE

resultDataFrame = DynamicFrame.fromDF(joined_df, glueContext, "resultDataFrame")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=resultDataFrame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": target_destination, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")

job.commit()