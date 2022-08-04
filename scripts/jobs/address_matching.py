import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var

## write into the log file with:
## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
perfect_match_s3_bucket_target = get_glue_env_var('perfect_match_s3_bucket_target', '')
best_match_s3_bucket_target = get_glue_env_var('best_match_s3_bucket_target', '')
imperfect_s3_bucket_target = get_glue_env_var('imperfect_s3_bucket_target', '')
non_match_s3_bucket_target = get_glue_env_var('non_match_s3_bucket_target', '')

query_addresses_url = get_glue_env_var('query_addresses_url', '')
target_addresses_url = get_glue_env_var('target_addresses_url', '')
sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
logger.info('fetch first set of data')
query_addresses = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    format="parquet",
    connection_options={
        "paths": [query_addresses_url],
        "recurse": True
    },
    transformation_ctx="query_addresses"
)
query_addresses_df = query_addresses.toDF()
logger.info('concat first set of data')
query_concat = query_addresses_df.withColumn(
    "concat_address",
    F.concat_ws(" ", "concatenated_string_to_match", "postcode")
)
logger.info('fetch second set of data')
target_addresses = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    format="parquet",
    connection_options={"paths": [target_addresses_url], "recurse": True},
    transformation_ctx="target_addresses"
)
target_addresses_df = target_addresses.toDF()
logger.info('concat seconds set of data')
target_concat_address = target_addresses_df.withColumn(
    "concat_address",
    F.concat_ws(" ", "concatenated2", "postcode")
)
# would be nice to make this optional: that creates a subset of LLPG based on the postcodes in the list of addresses to match
target_concat_address = target_concat_address.join(query_concat, "postcode","leftsemi")
model = Pipeline(stages=[
    RegexTokenizer(
        pattern="", inputCol="concat_address", outputCol="tokens", minTokenLength=1
    ),
    NGram(n=3, inputCol="tokens", outputCol="ngrams"),
    HashingTF(inputCol="ngrams", outputCol="vectors"),
    MinHashLSH(inputCol="vectors", outputCol="lsh")
]).fit(target_concat_address)
target_hashed = model.transform(target_concat_address)
query_hashed = model.transform(query_concat)
joined = model.stages[-1].approxSimilarityJoin(
    query_hashed.withColumnRenamed("concat_address", "query_address"),
    target_hashed.withColumnRenamed("concat_address", "result_address"),
    1 # when in the restricted mode (line 77), it's better to set the threshold to 0.7
)
window = Window.partitionBy(joined['datasetA.query_address']).orderBy(joined['distCol'])
ranked = joined.select('*', rank().over(window).alias('rank'))
ranked_frame = ranked.select(
    'datasetA.query_address',
    'datasetB.result_address',
    'datasetB.uprn',
    'distCol',
    'rank',
    'datasetA.prinx'
)
# only keep best match and remove duplicates
bestMatch = ranked_frame.filter(col('rank') == 1).dropDuplicates(['prinx'])
nonMatch = query_concat.join(bestMatch, "prinx", "leftanti")
perfectMatch = bestMatch.filter('distCol = 0')
imperfectMatch = bestMatch.filter('distCol != 0')
# results = bestMatch.union(nonMatch)
bestMatchframe = DynamicFrame.fromDF(bestMatch, glueContext, "bestMatch")
nonMatchframe = DynamicFrame.fromDF(nonMatch, glueContext, "nonMatch")
imperfectMatchframe = DynamicFrame.fromDF(imperfectMatch, glueContext, "imperfectMatch")
perfectMatchframe = DynamicFrame.fromDF(perfectMatch, glueContext, "perfectMatch")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=perfectMatchframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": perfect_match_s3_bucket_target, "partitionKeys": []},
    transformation_ctx="parquetData")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=bestMatchframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": best_match_s3_bucket_target, "partitionKeys": []},
    transformation_ctx="parquetData")


parquetData = glueContext.write_dynamic_frame.from_options(
    frame=imperfectMatchframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": imperfect_s3_bucket_target, "partitionKeys": []},
    transformation_ctx="parquetData")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=nonMatchframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": non_match_s3_bucket_target, "partitionKeys": []},
    transformation_ctx="parquetData")
job.commit()
