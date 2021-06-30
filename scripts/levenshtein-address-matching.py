import sys
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F
from pyspark import SparkContext
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql.functions import col, max

from helpers import get_glue_env_var, PARTITION_KEYS

glueContext = GlueContext(SparkContext.getOrCreate())
job = Job(glueContext)
# logger = glueContext.get_logger()

def get_latest_partitions(dfa):
   dfa = dfa.where(col('import_year') == dfa.select(max('import_year')).first()[0])
   dfa = dfa.where(col('import_month') == dfa.select(max('import_month')).first()[0])
   dfa = dfa.where(col('import_day') == dfa.select(max('import_day')).first()[0])
   return dfa

source_data = get_glue_env_var('source_data', '')
target_destination = get_glue_env_var('target_destination', '')
addresses_api_data = get_glue_env_var('addresses_api_data', '')

# logger.info('fetch repairs data from parquet and turn them into DF')

query_addresses_ddf = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    format="parquet",
    connection_options={
        "paths": [source_data],
        "recurse": True
    },
    transformation_ctx="query_addresses"
)

query_addresses = query_addresses_ddf.toDF()
query_addresses = get_latest_partitions(query_addresses)
query_addresses.count()

# logger.info('create a sample')
query_addresses = query_addresses.sample(0.5,123)
# logger.info(query_addresses.count())


# logger.info('concat query data')
query_addresses = query_addresses.filter("concatenated_string_to_match != ''")

query_concat = query_addresses.withColumn(
    "query_address",
    F.concat_ws(" ", "concatenated_string_to_match", "postcode")
)


# logger.info('fetch Addresses API data from csv'- works)
target_addresses_ddf = glueContext.create_dynamic_frame_from_options(
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": [addresses_api_data]
    },
    format_options={
        "withHeader": True,
        "separator": ","
    }
)
target_addresses = target_addresses_ddf.toDF()

target_concat = target_addresses.select("line1", "line2", "line3", "postcode", "uprn")
target_concat = target_concat.withColumn(
    "concat_lines",
    F.concat_ws(" ", "line1", "line2", "line3")
)

# logger.info('remove HACKNEY if at the end of the line')
target_concat = target_concat.withColumn("concat_lines", F.trim(F.col("concat_lines")))
target_concat = target_concat.withColumn("address_length", F.length(F.col("concat_lines")))
target_concat = target_concat.withColumn("concat_lines",
       F.when(F.col("concat_lines").endswith(" HACKNEY"), F.expr("substring(concat_lines, 1, address_length -8)"))
          .otherwise(F.col("concat_lines")))


# logger.info('add postcode to the end of the line')
target_concat = target_concat.withColumn(
    "target_address",
    F.concat_ws(" ", "concat_lines", "postcode")
)

cross = query_concat.crossJoin(target_concat)
cross_compare = cross.withColumn("levenshtein", F.levenshtein(F.col("query_address"), F.col("target_address")))

# logger.info('Only keep distance <11')
cross_compare = cross_compare.select('prinx','query_address', 'target_address', 'levenshtein', 'uprn').filter("levenshtein < 11")



# logger.info('Rank and keeps best match')
window = Window.partitionBy('prinx').orderBy("levenshtein")

bestMatch = cross_compare.withColumn('rank', F.rank().over(window))\
 .filter('rank = 1')\
 .dropDuplicates(['prinx'])



# logger.info('write into parquet')
resultDataFrame = DynamicFrame.fromDF(bestMatch, glueContext, "resultDataFrame")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=resultDataFrame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": target_destination, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")


job.commit()