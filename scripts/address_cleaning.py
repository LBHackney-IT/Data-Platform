import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col, trim, when, max
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame

from helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

## write into the log file with:
## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

cleaned_addresses_s3_bucket_target = get_glue_env_var('cleaned_addresses_s3_bucket_target', '')
source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
source_address_column_header = get_glue_env_var('source_address_column_header', '')
source_postcode_column_header = get_glue_env_var('source_postcode_column_header', '')


sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info('Fetch Source Data')
source_dataset = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
)

df = source_dataset.toDF()
source_dataset.printSchema()

tmp = get_latest_partitions(df)

logger.info('adding new column')
df = df.withColumn('address', F.col(source_address_column_header))

logger.info('extract postcode into a new column')
df = df.withColumn('postcode', F.regexp_extract(F.col('address'), '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})', 1))

logger.info('remove postcode from address')
df = df.withColumn('address', F.regexp_replace(F.col('address'), '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})', ''))



if source_postcode_column_header:
    logger.info('populate empty postcode with postcode from the other PC column')
    df = df.withColumn("postcode", \
       F.when(F.col("postcode")=="" ,None) \
          .otherwise(F.col("postcode")))
    df = df.withColumn("postcode", F.coalesce(F.col('postcode'),F.col(source_postcode_column_header)))

logger.info('postcode formatting')
df = df.withColumn("postcode", F.upper(F.col("postcode")))
df = df.withColumn("postcode_nospace", F.regexp_replace(F.col("postcode"), " +", ""))
df = df.withColumn("postcode_length", F.length(F.col("postcode_nospace")))
df = df.withColumn("postcode_start", F.expr("substring(postcode_nospace, 1, postcode_length -3)"))
df = df.withColumn("postcode_end", F.expr("substring(postcode_nospace, -3, 3)"))
df = df.withColumn("postcode", F.concat_ws(" ", "postcode_start", "postcode_end"))

logger.info('address line formatting - remove commas and extra spaces')
df = df.withColumn("address", F.upper(F.col("address")))
df = df.withColumn("address", F.regexp_replace(F.col("address"), ",", ""))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " +", " "))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " ?- ?\z", ""))


logger.info('address line formatting - remove LONDON at the end (dont do this for out of London matching)')
df = df.withColumn("address", F.trim(F.col("address")))
df = df.withColumn("address_length", F.length(F.col("address")))
df = df.withColumn("address", \
       F.when(F.col("address").endswith(" LONDON"), F.expr("substring(address, 1, address_length -7)")) \
          .otherwise(F.col("address")))

logger.info('address line formatting - remove HACKNEY at the end (dont necessarily this for out of borough matching)')
df = df.withColumn("address", F.trim(F.col("address")))
df = df.withColumn("address_length", F.length(F.col("address")))
df = df.withColumn("address", \
       F.when(F.col("address").endswith(" HACKNEY"), F.expr("substring(address, 1, address_length -8)")) \
          .otherwise(F.col("address")))

logger.info('address line formatting - dashes between numbers: remove extra spaces')
df = df.withColumn("address", F.regexp_replace(F.col("address"), '(\\d+) ?- ?(\\d+)', '$1-$2'))

logger.info('deal with abbreviations')

logger.info('for \'street\': we only replace st if it is at the end of the string, if not there is a risk of confusion with saint')
df = df.withColumn("address", F.regexp_replace(F.col("address"), " ST.?\z", " STREET"))

df = df.withColumn("address", F.regexp_replace(F.col("address"), " RD.? ", " ROAD "))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " RD.?\z", " ROAD"))

df = df.withColumn("address", F.regexp_replace(F.col("address"), " AVE ", " AVENUE "))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " AVE\z", " AVENUE"))

df = df.withColumn("address", F.regexp_replace(F.col("address"), " HSE ", " HOUSE "))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " HSE\z", " HOUSE"))

df = df.withColumn("address", F.regexp_replace(F.col("address"), " CT.? ", " COURT "))
df = df.withColumn("address", F.regexp_replace(F.col("address"), " CT.?\z", " COURT"))

# df = df.withColumn("address", F.regexp_replace(F.col("address"), " ST.? ", " SAINT "))

df = df.withColumnRenamed("address", "concatenated_string_to_match")

logger.info('create a unique ID')
df = df.withColumn("prinx", F.monotonically_increasing_id()).repartition(1)

logger.info('write into parquet')
cleanedDataframe = DynamicFrame.fromDF(df, glueContext, "cleanedDataframe")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_addresses_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")

job.commit()